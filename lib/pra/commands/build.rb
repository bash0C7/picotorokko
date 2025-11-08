
require 'thor'
require 'pra/patch_applier'

module Pra
  module Commands
    # ビルド環境管理コマンド群（build/ディレクトリ）
    # 注: このコマンドはビルド環境（ファイルシステム上のワーキングディレクトリ）を管理する
    # 環境定義（メタデータ）は pra env コマンドで管理
    class Build < Thor
      def self.exit_on_failure?
        true
      end

      desc 'setup [ENV_NAME]', 'Setup build environment from environment definition (.picoruby-env.yml)'
      def setup(env_name = 'current')
        # currentの場合はsymlinkから実環境定義名を取得
        if env_name == 'current'
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          if File.symlink?(current_link)
            current = Pra::Env.get_current_env
            env_name = current if current
          else
            raise "Error: No current environment definition set in .picoruby-env.yml. Use 'pra env set ENV_NAME' first"
          end
        end

        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment definition '#{env_name}' not found in .picoruby-env.yml" if env_config.nil?

        # env-hashを生成
        hashes = Pra::Env.compute_env_hash(env_name)
        raise "Error: Failed to compute environment hash for '#{env_name}'" if hashes.nil?

        r2p2_hash, esp32_hash, picoruby_hash, env_hash = hashes

        build_path = Pra::Env.get_build_path(env_hash)

        # キャッシュが存在するか確認
        r2p2_cache = Pra::Env.get_cache_path('R2P2-ESP32', r2p2_hash)
        esp32_cache = Pra::Env.get_cache_path('picoruby-esp32', esp32_hash)
        picoruby_cache = Pra::Env.get_cache_path('picoruby', picoruby_hash)

        unless Dir.exist?(r2p2_cache)
          raise "Error: R2P2-ESP32 cache not found. Run 'pra cache fetch #{env_name}' first"
        end
        unless Dir.exist?(esp32_cache)
          raise "Error: picoruby-esp32 cache not found. Run 'pra cache fetch #{env_name}' first"
        end
        unless Dir.exist?(picoruby_cache)
          raise "Error: picoruby cache not found. Run 'pra cache fetch #{env_name}' first"
        end

        puts "Setting up build environment from environment definition: #{env_name}"

        # ビルドディレクトリを作成
        FileUtils.mkdir_p(Pra::Env::BUILD_DIR)

        if Dir.exist?(build_path)
          puts '  ✓ Build environment already exists'
        else
          puts "  Creating build environment at #{build_path}"
          FileUtils.mkdir_p(build_path)

          # キャッシュからコピー
          puts '  Copying R2P2-ESP32...'
          FileUtils.cp_r(r2p2_cache, File.join(build_path, 'R2P2-ESP32'))

          puts '  Copying picoruby-esp32...'
          esp32_dest = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32')
          FileUtils.rm_rf(esp32_dest) if Dir.exist?(esp32_dest)
          FileUtils.cp_r(esp32_cache, esp32_dest)

          puts '  Copying picoruby...'
          picoruby_dest = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32', 'picoruby')
          FileUtils.rm_rf(picoruby_dest) if Dir.exist?(picoruby_dest)
          FileUtils.cp_r(picoruby_cache, picoruby_dest)

          # パッチを適用
          apply_patches(env_name, build_path)

          # PicoRuby ビルド環境のセットアップ（rake setup_esp32）
          puts '  Setting up PicoRuby build environment...'
          r2p2_path = File.join(build_path, 'R2P2-ESP32')
          begin
            Pra::Env.execute_with_esp_env('rake setup_esp32', r2p2_path)
            puts '  ✓ PicoRuby build environment ready'
          rescue StandardError => e
            puts "  ✗ Warning: Failed to run rake setup_esp32: #{e.message}"
            puts '  You may need to run it manually later.'
          end

          # storage/homeをコピー
          puts '  Copying storage/home...'
          home_src = File.join(Pra::Env::STORAGE_HOME)
          home_dest = File.join(build_path, 'R2P2-ESP32', 'storage', 'home')
          FileUtils.rm_rf(home_dest) if Dir.exist?(home_dest)
          FileUtils.mkdir_p(File.dirname(home_dest))
          FileUtils.cp_r(home_src, home_dest) if Dir.exist?(home_src)
        end

        # Appのmrbgem雛形を生成（存在しない場合のみ）
        generate_app_mrbgem

        # Appのmrbgem用パッチを生成
        generate_app_patches

        # Symlinkを更新
        puts '  Updating symlink: build/current'
        current_link = File.join(Pra::Env::BUILD_DIR, 'current')
        Pra::Env.create_symlink(File.basename(build_path), current_link)
        Pra::Env.set_current_env(env_name)

        puts "✓ Build environment ready for environment definition: #{env_name}"
      end

      desc 'clean [ENV_NAME]', 'Delete specified build environment directory'
      def clean(env_name = 'current')
        # currentの場合はsymlinkから実環境定義を取得
        if env_name == 'current'
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          if File.symlink?(current_link)
            target = File.readlink(current_link)
            build_path = File.join(Pra::Env::BUILD_DIR, target)
            FileUtils.rm_rf(build_path) if Dir.exist?(build_path)
            FileUtils.rm_f(current_link)
            Pra::Env.set_current_env(nil)
            puts '✓ Current build environment removed'
          else
            puts 'No current environment to clean'
          end
        else
          env_config = Pra::Env.get_environment(env_name)
          raise "Error: Environment definition '#{env_name}' not found in .picoruby-env.yml" if env_config.nil?

          hashes = Pra::Env.compute_env_hash(env_name)
          raise "Error: Failed to compute environment hash for '#{env_name}'" if hashes.nil?

          _r2p2_hash, _esp32_hash, _picoruby_hash, env_hash = hashes
          build_path = Pra::Env.get_build_path(env_hash)

          if Dir.exist?(build_path)
            puts "Removing build environment for environment definition: #{env_name}"
            FileUtils.rm_rf(build_path)
            puts '✓ Build environment directory removed'
          else
            puts "Build environment directory not found for environment definition: #{env_name}"
          end
        end
      end

      desc 'list', 'Display list of constructed build environment directories'
      def list
        puts "=== Build Environments ===\n"

        current_link = File.join(Pra::Env::BUILD_DIR, 'current')
        if File.symlink?(current_link)
          target = File.readlink(current_link)
          puts "Current: build/current -> #{target}/\n"
        else
          puts "Current: (not set)\n"
        end

        if Dir.exist?(Pra::Env::BUILD_DIR)
          puts 'Available:'
          Dir.entries(Pra::Env::BUILD_DIR).sort.each do |entry|
            next if ['.', '..', 'current'].include?(entry)

            build_path = File.join(Pra::Env::BUILD_DIR, entry)
            next unless File.directory?(build_path)

            size = `du -sh #{Shellwords.escape(build_path)} 2>/dev/null`.split.first || '0'
            puts "  #{entry}  (#{size})"
          end
        else
          puts 'No build environments found'
        end
      end

      private

      # Appのmrbgem雛形を生成（存在しない場合のみ）
      def generate_app_mrbgem
        app_dir = File.join(Dir.pwd, 'mrbgems', 'App')
        return if Dir.exist?(app_dir)

        puts '  Generating App mrbgem template...'
        Pra::Commands::Mrbgems.new.generate('App')
        puts '  ✓ Generated App mrbgem template'
      end

      # Appのmrbgem用パッチを生成
      def generate_app_patches
        puts '  Generating App mrbgem patches...'

        # build_config パッチを生成
        generate_build_config_patch

        # CMakeLists.txt パッチを生成
        generate_cmake_patch

        puts '  ✓ Generated App mrbgem patches'
      end

      # build_config パッチを生成
      def generate_build_config_patch
        patch_file = File.join(Pra::Env::PATCH_DIR, 'picoruby', 'build_config', 'xtensa-esp.rb')
        FileUtils.mkdir_p(File.dirname(patch_file))

        # 既存パッチを読み込むか新規作成
        if File.exist?(patch_file)
          content = File.read(patch_file)
          # 既に App の記載があるかチェック
          return if content.include?("conf.gem local: '../../../../mrbgems/App'")

          # 末尾に追記
          File.write(patch_file,
                     content + "\n# Application-specific mrbgem\nconf.gem local: '../../../../mrbgems/App'\n")
        else
          # 新規作成（最小限の内容）
          File.write(patch_file, "# Application-specific mrbgem\nconf.gem local: '../../../../mrbgems/App'\n")
        end
      end

      # CMakeLists.txt パッチを生成
      def generate_cmake_patch
        patch_file = File.join(Pra::Env::PATCH_DIR, 'picoruby-esp32', 'CMakeLists.txt')
        FileUtils.mkdir_p(File.dirname(patch_file))

        # 既存パッチを読み込むか新規作成
        if File.exist?(patch_file)
          content = File.read(patch_file)
          # 既に App の記載があるかチェック
          return if content.include?('../../mrbgems/App/src/app.c')

          # 末尾に追記（簡潔なフォーマット）
          File.write(patch_file,
                     content + "\n# Application-specific mrbgem (App)\n${COMPONENT_DIR}/../../mrbgems/App/src/app.c\n")
        else
          # 新規作成（最小限の内容）
          File.write(patch_file, "# Application-specific mrbgem (App)\n${COMPONENT_DIR}/../../mrbgems/App/src/app.c\n")
        end
      end

      # パッチ適用処理
      def apply_patches(env_name, build_path)
        puts '  Applying patches...'

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          patch_repo_dir = File.join(Pra::Env::PATCH_DIR, repo)
          next unless Dir.exist?(patch_repo_dir)

          case repo
          when 'R2P2-ESP32'
            work_path = File.join(build_path, 'R2P2-ESP32')
          when 'picoruby-esp32'
            work_path = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32')
          when 'picoruby'
            work_path = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32', 'picoruby')
          end

          next unless Dir.exist?(work_path)

          # パッチを適用
          Pra::PatchApplier.apply_patches_to_directory(patch_repo_dir, work_path)
          puts "    Applied #{repo}"
        end

        puts '  ✓ Patches applied'
      end
    end
  end
end
