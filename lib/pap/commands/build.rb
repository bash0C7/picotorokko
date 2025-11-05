
require 'thor'

module Pap
  module Commands
    # ビルド環境管理コマンド群
    class Build < Thor
      def self.exit_on_failure?
        true
      end

      desc 'setup [ENV_NAME]', 'Setup build environment for specified environment'
      def setup(env_name = 'current')
        # currentの場合はsymlinkから実環境名を取得
        if env_name == 'current'
          current_link = File.join(Pap::Env::BUILD_DIR, 'current')
          if File.symlink?(current_link)
            current = Pap::Env.get_current_env
            env_name = current if current
          else
            raise "Error: No current environment set. Use 'pap env set ENV_NAME' first"
          end
        end

        env_config = Pap::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        # env-hashを生成
        r2p2_hash = env_config['R2P2-ESP32']['commit'] + '-' + env_config['R2P2-ESP32']['timestamp']
        esp32_hash = env_config['picoruby-esp32']['commit'] + '-' + env_config['picoruby-esp32']['timestamp']
        picoruby_hash = env_config['picoruby']['commit'] + '-' + env_config['picoruby']['timestamp']
        env_hash = Pap::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)

        build_path = Pap::Env.get_build_path(env_hash)

        # キャッシュが存在するか確認
        r2p2_cache = Pap::Env.get_cache_path('R2P2-ESP32', r2p2_hash)
        esp32_cache = Pap::Env.get_cache_path('picoruby-esp32', esp32_hash)
        picoruby_cache = Pap::Env.get_cache_path('picoruby', picoruby_hash)

        unless Dir.exist?(r2p2_cache)
          raise "Error: R2P2-ESP32 cache not found. Run 'pap cache fetch #{env_name}' first"
        end
        unless Dir.exist?(esp32_cache)
          raise "Error: picoruby-esp32 cache not found. Run 'pap cache fetch #{env_name}' first"
        end
        unless Dir.exist?(picoruby_cache)
          raise "Error: picoruby cache not found. Run 'pap cache fetch #{env_name}' first"
        end

        puts "Setting up build environment: #{env_name}"

        # ビルドディレクトリを作成
        FileUtils.mkdir_p(Pap::Env::BUILD_DIR)

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

          # storage/homeをコピー
          puts '  Copying storage/home...'
          home_src = File.join(Pap::Env::STORAGE_HOME)
          home_dest = File.join(build_path, 'R2P2-ESP32', 'storage', 'home')
          FileUtils.rm_rf(home_dest) if Dir.exist?(home_dest)
          FileUtils.mkdir_p(File.dirname(home_dest))
          FileUtils.cp_r(home_src, home_dest) if Dir.exist?(home_src)
        end

        # Symlinkを更新
        puts '  Updating symlink: build/current'
        current_link = File.join(Pap::Env::BUILD_DIR, 'current')
        Pap::Env.create_symlink(File.basename(build_path), current_link)
        Pap::Env.set_current_env(env_name)

        puts "✓ Build environment ready for: #{env_name}"
      end

      desc 'clean [ENV_NAME]', 'Delete specified build environment'
      def clean(env_name = 'current')
        # currentの場合はsymlinkから実環境を取得
        if env_name == 'current'
          current_link = File.join(Pap::Env::BUILD_DIR, 'current')
          if File.symlink?(current_link)
            target = File.readlink(current_link)
            build_path = File.join(Pap::Env::BUILD_DIR, target)
            FileUtils.rm_rf(build_path) if Dir.exist?(build_path)
            FileUtils.rm_f(current_link)
            Pap::Env.set_current_env(nil)
            puts '✓ Current build environment removed'
          else
            puts 'No current environment to clean'
          end
        else
          env_config = Pap::Env.get_environment(env_name)
          raise "Error: Environment '#{env_name}' not found" if env_config.nil?

          r2p2_hash = env_config['R2P2-ESP32']['commit'] + '-' + env_config['R2P2-ESP32']['timestamp']
          esp32_hash = env_config['picoruby-esp32']['commit'] + '-' + env_config['picoruby-esp32']['timestamp']
          picoruby_hash = env_config['picoruby']['commit'] + '-' + env_config['picoruby']['timestamp']
          env_hash = Pap::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pap::Env.get_build_path(env_hash)

          if Dir.exist?(build_path)
            puts "Removing build environment: #{env_name}"
            FileUtils.rm_rf(build_path)
            puts '✓ Build environment removed'
          else
            puts "Build environment not found: #{env_name}"
          end
        end
      end

      desc 'list', 'Display list of constructed build environments'
      def list
        puts "=== Build Environments ===\n"

        current_link = File.join(Pap::Env::BUILD_DIR, 'current')
        if File.symlink?(current_link)
          target = File.readlink(current_link)
          puts "Current: build/current -> #{target}/\n"
        else
          puts "Current: (not set)\n"
        end

        if Dir.exist?(Pap::Env::BUILD_DIR)
          puts 'Available:'
          Dir.entries(Pap::Env::BUILD_DIR).sort.each do |entry|
            next if ['.', '..', 'current'].include?(entry)

            build_path = File.join(Pap::Env::BUILD_DIR, entry)
            next unless File.directory?(build_path)

            size = `du -sh #{Shellwords.escape(build_path)} 2>/dev/null`.split.first || '0'
            puts "  #{entry}  (#{size})"
          end
        else
          puts 'No build environments found'
        end
      end

      private

      # パッチ適用処理
      def apply_patches(env_name, build_path)
        puts '  Applying patches...'

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          patch_repo_dir = File.join(Pap::Env::PATCH_DIR, repo)
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

          # patch/repo配下のファイルをrecursiveに適用
          Dir.glob("#{patch_repo_dir}/**/*").sort.each do |patch_file|
            next if File.directory?(patch_file)
            next if File.basename(patch_file) == '.keep'

            rel_path = patch_file.sub("#{patch_repo_dir}/", '')
            dest_file = File.join(work_path, rel_path)

            FileUtils.mkdir_p(File.dirname(dest_file))
            FileUtils.cp(patch_file, dest_file)
          end

          puts "    Applied #{repo}"
        end

        puts '  ✓ Patches applied'
      end
    end
  end
end
