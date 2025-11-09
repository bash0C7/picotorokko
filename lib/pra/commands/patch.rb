
require 'thor'
require 'pra/patch_applier'

module Pra
  module Commands
    # パッチ管理コマンド群
    class Patch < Thor
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

        hashes = Pra::Env.compute_env_hash(env_name)
        raise "Error: Failed to compute environment hash for '#{env_name}'" if hashes.nil?

        _r2p2_hash, _esp32_hash, _picoruby_hash, env_hash = hashes
        build_path = Pra::Env.get_build_path(env_hash)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "Exporting patches from: #{env_name}"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          work_path = resolve_work_path(repo, build_path)
          next unless Dir.exist?(work_path)

          export_repo_changes(repo, work_path)
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

        hashes = Pra::Env.compute_env_hash(env_name)
        raise "Error: Failed to compute environment hash for '#{env_name}'" if hashes.nil?

        _r2p2_hash, _esp32_hash, _picoruby_hash, env_hash = hashes
        build_path = Pra::Env.get_build_path(env_hash)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

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

        hashes = Pra::Env.compute_env_hash(env_name)
        raise "Error: Failed to compute environment hash for '#{env_name}'" if hashes.nil?

        _r2p2_hash, _esp32_hash, _picoruby_hash, env_hash = hashes
        build_path = Pra::Env.get_build_path(env_hash)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "=== Patch Differences ===\n"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          patch_repo_dir = File.join(Pra::Env::PATCH_DIR, repo)
          work_path = resolve_work_path(repo, build_path)

          show_repo_diff(repo, patch_repo_dir, work_path)
        end
      end

      private

      def resolve_work_path(repo, build_path)
        case repo
        when 'R2P2-ESP32'
          File.join(build_path, 'R2P2-ESP32')
        when 'picoruby-esp32'
          File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32')
        when 'picoruby'
          File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32', 'picoruby')
        end
      end

      def export_repo_changes(repo, work_path)
        Dir.chdir(work_path) do
          changed_files = `git diff --name-only 2>/dev/null`.split("\n")

          if changed_files.empty?
            puts "  #{repo}: (no changes)"
            return
          end

          puts "  #{repo}: #{changed_files.size} file(s)"

          changed_files.each do |file|
            patch_dir = File.join(Pra::Env::PATCH_DIR, repo)
            FileUtils.mkdir_p(patch_dir) unless Dir.exist?(patch_dir)

            file_dir = File.dirname(file)
            FileUtils.mkdir_p(File.join(patch_dir, file_dir)) unless file_dir == '.'

            diff_output = `git diff #{Shellwords.escape(file)}`
            patch_file = File.join(patch_dir, file)

            if diff_output.strip.empty?
              FileUtils.cp(file, patch_file)
            else
              File.write(patch_file, diff_output)
            end

            puts "    Exported: #{repo}/#{file}"
          end
        end
      end

      def show_repo_diff(repo, patch_repo_dir, work_path)
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
