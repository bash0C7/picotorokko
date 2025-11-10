
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

      desc 'show', 'Display current environment definition from .picoruby-env.yml'
      def show
        current = Pra::Env.get_current_env
        if current.nil?
          puts 'Current environment definition: (not set)'
          puts "Run 'pra env set ENV_NAME' to set an environment definition"
        else
          env_config = Pra::Env.get_environment(current)
          if env_config.nil?
            puts "Error: Environment '#{current}' not found in .picoruby-env.yml"
          else
            puts "Current environment definition: #{current}"

            # Symlink情報（ビルド環境）
            current_link = File.join(Pra::Env::BUILD_DIR, 'current')
            if File.symlink?(current_link)
              target = File.readlink(current_link)
              puts "Symlink: #{File.basename(current_link)} -> #{File.basename(target)}/"
            end

            puts "\nRepo versions:"
            %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
              info = env_config[repo] || {}
              commit = info['commit'] || 'N/A'
              timestamp = info['timestamp'] || 'N/A'
              puts "  #{repo}: #{commit} (#{timestamp})"
            end

            puts "\nCreated: #{env_config['created_at']}"
            puts "Notes: #{env_config['notes']}" unless env_config['notes'].to_s.empty?
          end
        end
      end

      desc 'set ENV_NAME', 'Switch to specified environment definition (updates build/current symlink)'
      def set(env_name)
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
    end
  end
end
