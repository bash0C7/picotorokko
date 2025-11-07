
require 'thor'
require_relative '../patch_applier'

module Pra
  module Commands
    # パッチ管理コマンド群
    class Patch < Thor
      include Pra::PatchApplier

      def self.exit_on_failure?
        true
      end

      desc 'export [ENV_NAME]', 'Export changes from build environment to patch directory'
      def export(env_name = 'current')
        # currentの場合はsymlinkから実環境名を取得
        if env_name == 'current'
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          if File.symlink?(current_link)
            current = Pra::Env.get_current_env
            env_name = current if current
          else
            raise 'Error: No current environment set'
          end
        end

        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        env_hash = Pra::Env.compute_env_hash(env_config)
        build_path = Pra::Env.get_build_path(env_hash)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "Exporting patches from: #{env_name}"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          case repo
          when 'R2P2-ESP32'
            work_path = File.join(build_path, 'R2P2-ESP32')
          when 'picoruby-esp32'
            work_path = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32')
          when 'picoruby'
            work_path = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32', 'picoruby')
          end

          next unless Dir.exist?(work_path)

          Dir.chdir(work_path) do
            # 変更ファイルを取得
            changed_files = `git diff --name-only 2>/dev/null`.split("\n")

            if changed_files.empty?
              puts "  #{repo}: (no changes)"
              next
            end

            puts "  #{repo}: #{changed_files.size} file(s)"

            changed_files.each do |file|
              patch_dir = File.join(Pra::Env::PATCH_DIR, repo)
              FileUtils.mkdir_p(patch_dir) unless Dir.exist?(patch_dir)

              # ディレクトリ構造を作成
              file_dir = File.dirname(file)
              FileUtils.mkdir_p(File.join(patch_dir, file_dir)) unless file_dir == '.'

              # 差分を取得して保存
              diff_output = `git diff #{Shellwords.escape(file)}`
              patch_file = File.join(patch_dir, file)

              if diff_output.strip.empty?
                # git diffが空の場合、ファイル全体をコピー
                FileUtils.cp(file, patch_file)
              else
                # 差分をファイルに保存
                File.write(patch_file, diff_output)
              end

              puts "    Exported: #{repo}/#{file}"
            end
          end
        end

        puts '✓ Patches exported'
      end

      desc 'apply [ENV_NAME]', 'Apply patches to build environment'
      def apply(env_name = 'current')
        # currentの場合はsymlinkから実環境名を取得
        if env_name == 'current'
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          if File.symlink?(current_link)
            current = Pra::Env.get_current_env
            env_name = current if current
          else
            # currentが設定されていない場合は、パッチ適用をスキップ
            puts '  (No current environment - skipping patch apply)'
            return
          end
        end

        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        env_hash = Pra::Env.compute_env_hash(env_config)
        build_path = Pra::Env.get_build_path(env_hash)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        apply_patches(build_path)
      end

      desc 'diff [ENV_NAME]', 'Display differences between working changes and stored patches'
      def diff(env_name = 'current')
        # currentの場合はsymlinkから実環境名を取得
        if env_name == 'current'
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          if File.symlink?(current_link)
            current = Pra::Env.get_current_env
            env_name = current if current
          else
            raise 'Error: No current environment set'
          end
        end

        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        r2p2_hash = env_config['R2P2-ESP32']['commit'] + '-' + env_config['R2P2-ESP32']['timestamp']
        esp32_hash = env_config['picoruby-esp32']['commit'] + '-' + env_config['picoruby-esp32']['timestamp']
        picoruby_hash = env_config['picoruby']['commit'] + '-' + env_config['picoruby']['timestamp']
        env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)

        build_path = Pra::Env.get_build_path(env_hash)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "=== Patch Differences ===\n"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          patch_repo_dir = File.join(Pra::Env::PATCH_DIR, repo)

          case repo
          when 'R2P2-ESP32'
            work_path = File.join(build_path, 'R2P2-ESP32')
          when 'picoruby-esp32'
            work_path = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32')
          when 'picoruby'
            work_path = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32', 'picoruby')
          end

          puts "#{repo}:"

          if Dir.exist?(work_path)
            Dir.chdir(work_path) do
              changed = `git diff --name-only 2>/dev/null`.split("\n")
              if changed.empty?
                puts '  (no working changes)'
              else
                puts "  Working changes: #{changed.join(', ')}"
              end
            end
          end

          if Dir.exist?(patch_repo_dir)
            patch_files = Dir.glob("#{patch_repo_dir}/**/*").reject do |p|
              File.directory?(p) || File.basename(p) == '.keep'
            end
            if patch_files.empty?
              puts '  (no stored patches)'
            else
              puts "  Stored patches: #{patch_files.map { |p| p.sub("#{patch_repo_dir}/", '') }.join(', ')}"
            end
          else
            puts '  (no patches directory)'
          end

          puts
        end
      end
    end
  end
end
