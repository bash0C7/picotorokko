
require 'thor'

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

      desc 'show [ENV_NAME]', 'Display environment definition (current or specified) from .picoruby-env.yml'
      def show(env_name = nil)
        # Use provided env name, or fall back to current environment
        target_env = env_name || Pra::Env.get_current_env

        return show_no_env if target_env.nil?

        env_config = Pra::Env.get_environment(target_env)
        return show_env_not_found(target_env) if env_config.nil?

        show_env_details(target_env, env_config, env_name)
      end

      desc 'set ENV_NAME', 'Switch to specified environment or create new with options'
      option :commit, type: :string, desc: 'R2P2-ESP32 commit hash for new environment'
      option :branch, type: :string, desc: 'Git branch reference'
      def set(env_name)
        # validate environment name
        unless env_name.match?(Pra::Env::ENV_NAME_PATTERN)
          raise "Error: Invalid environment name '#{env_name}'. Must match pattern: #{Pra::Env::ENV_NAME_PATTERN}"
        end

        # Mode 1: Create new environment with commit option
        if options[:commit]
          r2p2_info = { 'commit' => options[:commit], 'timestamp' => Time.now.strftime('%Y%m%d_%H%M%S') }
          # For now, use placeholder values for esp32 and picoruby
          esp32_info = { 'commit' => 'placeholder', 'timestamp' => Time.now.strftime('%Y%m%d_%H%M%S') }
          picoruby_info = { 'commit' => 'placeholder', 'timestamp' => Time.now.strftime('%Y%m%d_%H%M%S') }

          notes = "Created with R2P2-ESP32 commit: #{options[:commit]}"
          notes += ", branch: #{options[:branch]}" if options[:branch]

          Pra::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info, notes: notes)
          puts "✓ Environment definition '#{env_name}' created with commit #{options[:commit]}"
          return
        end

        # Mode 2: Switch to existing environment (original behavior)
        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment definition '#{env_name}' not found in .picoruby-env.yml" if env_config.nil?

        # ビルド環境が存在するか確認
        hashes = Pra::Env.compute_env_hash(env_name)
        raise "Error: Failed to compute environment hash for '#{env_name}'" if hashes.nil?

        _r2p2_hash, _esp32_hash, _picoruby_hash, env_hash = hashes
        build_path = Pra::Env.get_build_path(env_hash)

        if Dir.exist?(build_path)
          puts "Switching to environment definition: #{env_name}"
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          Pra::Env.create_symlink(File.basename(build_path), current_link)
          Pra::Env.set_current_env(env_name)
          puts "✓ Switched to environment definition '#{env_name}' (build/current symlink updated)"
        else
          puts "Error: Build environment not found at #{build_path}"
          puts "Run 'pra build setup #{env_name}' first"
        end
      end

      desc 'reset ENV_NAME', 'Remove and recreate environment definition'
      def reset(env_name)
        # validate environment name
        unless env_name.match?(Pra::Env::ENV_NAME_PATTERN)
          raise "Error: Invalid environment name '#{env_name}'. Must match pattern: #{Pra::Env::ENV_NAME_PATTERN}"
        end

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

      def show_no_env
        puts 'Current environment definition: (not set)'
        puts "Run 'pra env set ENV_NAME' to set an environment definition"
      end

      def show_env_not_found(env_name)
        puts "Error: Environment '#{env_name}' not found in .picoruby-env.yml"
      end

      def show_env_details(target_env, env_config, env_name)
        # Display label based on whether we're showing current or specified env
        label = env_name ? 'Environment definition' : 'Current environment definition'
        puts "#{label}: #{target_env}"

        # Symlink情報（ビルド環境）- only for current environment
        show_symlink_info unless env_name

        display_repo_versions(env_config)
        display_metadata(env_config)
      end

      def show_symlink_info
        current_link = File.join(Pra::Env::BUILD_DIR, 'current')
        return unless File.symlink?(current_link)

        target = File.readlink(current_link)
        puts "Symlink: #{File.basename(current_link)} -> #{File.basename(target)}/"
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
    end
  end
end
