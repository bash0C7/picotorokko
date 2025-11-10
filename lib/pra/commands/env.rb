
require 'thor'
require 'pra/patch_applier'

module Pra
  module Commands
    # 環境定義管理コマンド群（.picoruby-env.yml）
    # 注: このコマンドは環境定義（メタデータ）を管理する
    # 実際のビルド環境（ファイルシステム）は pra build コマンドで管理
    class Env < Thor
      def self.exit_on_failure?
        true
      end

      desc 'list', 'List all defined environments'
      def list
        env_file = Pra::Env.load_env_file
        environments = env_file['environments'] || {}

        if environments.empty?
          puts 'No environments defined yet.'
          puts "Run 'pra env latest' to create one automatically"
        else
          puts 'Available environments:'
          environments.each do |env_name, env_config|
            puts "  - #{env_name}"
            if env_config.is_a?(Hash)
              puts "    Created: #{env_config['created_at']}"
              puts "    R2P2-ESP32: #{env_config['R2P2-ESP32']['commit']}" if env_config['R2P2-ESP32']
            end
          end
        end
      end

      desc 'show ENV_NAME', 'Display environment definition from .picoruby-env.yml'
      def show(env_name)
        env_config = Pra::Env.get_environment(env_name)
        return show_env_not_found(env_name) if env_config.nil?

        show_env_details(env_name, env_config)
      end

      desc 'set ENV_NAME', 'Create new environment with options'
      option :commit, type: :string, desc: 'R2P2-ESP32 commit hash for new environment', required: true
      option :branch, type: :string, desc: 'Git branch reference'
      def set(env_name)
        Pra::Env.validate_env_name!(env_name)

        # Create new environment
        r2p2_info = { 'commit' => options[:commit], 'timestamp' => Time.now.strftime('%Y%m%d_%H%M%S') }
        # For now, use placeholder values for esp32 and picoruby
        esp32_info = { 'commit' => 'placeholder', 'timestamp' => Time.now.strftime('%Y%m%d_%H%M%S') }
        picoruby_info = { 'commit' => 'placeholder', 'timestamp' => Time.now.strftime('%Y%m%d_%H%M%S') }

        notes = "Created with R2P2-ESP32 commit: #{options[:commit]}"
        notes += ", branch: #{options[:branch]}" if options[:branch]

        Pra::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info, notes: notes)
        puts "✓ Environment definition '#{env_name}' created with commit #{options[:commit]}"
      end

      desc 'reset ENV_NAME', 'Remove and recreate environment definition'
      def reset(env_name)
        Pra::Env.validate_env_name!(env_name)

        # Check if environment exists
        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment definition '#{env_name}' not found in .picoruby-env.yml" if env_config.nil?

        # Store original metadata before removal
        original_notes = env_config['notes']

        # Remove and recreate with new timestamps
        r2p2_info = { 'commit' => 'placeholder', 'timestamp' => Time.now.strftime('%Y%m%d_%H%M%S') }
        esp32_info = { 'commit' => 'placeholder', 'timestamp' => Time.now.strftime('%Y%m%d_%H%M%S') }
        picoruby_info = { 'commit' => 'placeholder', 'timestamp' => Time.now.strftime('%Y%m%d_%H%M%S') }

        notes = original_notes.to_s.empty? ? "Reset at #{Time.now}" : "#{original_notes} (reset at #{Time.now})"

        Pra::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info, notes: notes)
        puts "✓ Environment definition '#{env_name}' has been reset"
      end

      desc 'patch_export ENV_NAME', 'Export changes from build environment to patch directory'
      def patch_export(env_name)
        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        # Phase 4.1: Build path uses env_name directly
        build_path = Pra::Env.get_build_path(env_name)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "Exporting patches from: #{env_name}"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          work_path = resolve_work_path(repo, build_path)
          next unless Dir.exist?(work_path)

          export_repo_changes(repo, work_path)
        end

        puts '✓ Patches exported'
      end

      desc 'patch_apply ENV_NAME', 'Apply patches to build environment'
      def patch_apply(env_name)
        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        # Phase 4.1: Build path uses env_name directly
        build_path = Pra::Env.get_build_path(env_name)
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

          # Apply patches
          Pra::PatchApplier.apply_patches_to_directory(patch_repo_dir, work_path)
          puts "    Applied #{repo}"
        end

        puts '  ✓ Patches applied'
      end

      desc 'patch_diff ENV_NAME', 'Display differences between working changes and stored patches'
      def patch_diff(env_name)
        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        # Phase 4.1: Build path uses env_name directly
        build_path = Pra::Env.get_build_path(env_name)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        puts "=== Patch Differences ===\n"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          patch_repo_dir = File.join(Pra::Env::PATCH_DIR, repo)
          work_path = resolve_work_path(repo, build_path)

          show_repo_diff(repo, patch_repo_dir, work_path)
        end
      end

      desc 'latest', 'Fetch latest commit versions and create environment definition'
      def latest
        require 'tmpdir'

        puts 'Fetching latest commits from GitHub...'

        # 各リポジトリの最新コミットを取得
        repos_info = {}

        Pra::Env::REPOS.each do |repo_name, repo_url|
          puts "  Checking #{repo_name}..."

          # リモートから最新コミットを取得
          commit = Pra::Env.fetch_remote_commit(repo_url, 'HEAD')
          raise "Failed to fetch commit for #{repo_name}" if commit.nil?

          # 一時ディレクトリでshallow cloneしてタイムスタンプ取得
          Dir.mktmpdir do |tmpdir|
            tmp_repo = File.join(tmpdir, repo_name)
            puts "    Cloning to get timestamp..."

            # Shallow clone（高速化のため）
            unless system("git clone --depth 1 --branch HEAD #{Shellwords.escape(repo_url)} #{Shellwords.escape(tmp_repo)} 2>/dev/null")
              raise "Failed to clone #{repo_name}"
            end

            # コミットハッシュとタイムスタンプ取得
            Dir.chdir(tmp_repo) do
              short_hash = `git rev-parse --short=7 HEAD`.strip
              timestamp_str = `git show -s --format=%ci HEAD`.strip
              timestamp = Time.parse(timestamp_str).strftime('%Y%m%d_%H%M%S')

              repos_info[repo_name] = {
                'commit' => short_hash,
                'timestamp' => timestamp
              }

              puts "    ✓ #{repo_name}: #{short_hash} (#{timestamp})"
            end
          end
        end

        # latest環境として保存
        env_name = 'latest'
        puts "\nSaving as environment definition '#{env_name}' in .picoruby-env.yml..."

        Pra::Env.set_environment(
          env_name,
          repos_info['R2P2-ESP32'],
          repos_info['picoruby-esp32'],
          repos_info['picoruby'],
          notes: 'Auto-generated latest versions'
        )

        puts "✓ Environment definition '#{env_name}' created successfully in .picoruby-env.yml"
        puts "\nNext steps:"
        puts "  1. pra cache fetch #{env_name}  # Fetch repositories to cache"
        puts "  2. pra build setup #{env_name}  # Setup build environment"
      end

      private

      def show_env_not_found(env_name)
        puts "Error: Environment '#{env_name}' not found in .picoruby-env.yml"
      end

      def show_env_details(env_name, env_config)
        puts "Environment: #{env_name}"
        display_repo_versions(env_config)
        display_metadata(env_config)
      end

      def display_repo_versions(env_config)
        puts "\nRepo versions:"
        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          info = env_config[repo] || {}
          commit = info['commit'] || 'N/A'
          timestamp = info['timestamp'] || 'N/A'
          puts "  #{repo}: #{commit} (#{timestamp})"
        end
      end

      def display_metadata(env_config)
        puts "\nCreated: #{env_config['created_at']}"
        puts "Notes: #{env_config['notes']}" unless env_config['notes'].to_s.empty?
      end

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
            FileUtils.mkdir_p(patch_dir)

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
