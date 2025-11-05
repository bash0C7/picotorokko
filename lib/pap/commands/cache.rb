
require 'thor'
require 'set'

module Pap
  module Commands
    # キャッシュ管理コマンド群
    class Cache < Thor
      def self.exit_on_failure?
        true
      end

      desc 'list', 'Display list of cached repository versions'
      def list
        puts "=== Cached Repositories ===\n"

        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          repo_cache = File.join(Pap::Env::CACHE_DIR, repo)
          if Dir.exist?(repo_cache)
            puts "#{repo}:"
            Dir.entries(repo_cache).sort.reverse.each do |entry|
              next if ['.', '..'].include?(entry)

              puts "  #{entry}"
            end
          else
            puts "#{repo}: (no cache)"
          end
          puts
        end
      end

      desc 'fetch [ENV_NAME]', 'Fetch specified environment from GitHub and save to cache'
      def fetch(env_name = 'latest')
        puts "Fetching environment: #{env_name}"

        # 環境定義を読込
        env_config = Pap::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        # キャッシュディレクトリを作成
        FileUtils.mkdir_p(Pap::Env::CACHE_DIR)

        # 各リポジトリをキャッシュに保存
        repos_to_fetch = [
          { repo: 'R2P2-ESP32', url: Pap::Env::REPOS['R2P2-ESP32'], commit: env_config['R2P2-ESP32']['commit'] },
          { repo: 'picoruby-esp32', url: Pap::Env::REPOS['picoruby-esp32'],
            commit: env_config['picoruby-esp32']['commit'] },
          { repo: 'picoruby', url: Pap::Env::REPOS['picoruby'], commit: env_config['picoruby']['commit'] }
        ]

        repos_to_fetch.each do |repo_info|
          repo_name = repo_info[:repo]
          cache_hash = repo_info[:commit] + '-' + env_config[repo_name]['timestamp']
          cache_path = Pap::Env.get_cache_path(repo_name, cache_hash)

          if Dir.exist?(cache_path)
            puts "  ✓ #{repo_name} already cached"
          else
            puts "  Fetching #{repo_name}..."
            Pap::Env.clone_with_submodules(repo_info[:url], cache_path, repo_info[:commit])
            puts "  ✓ #{repo_name} cached to #{cache_path}"
          end
        end

        # R2P2-ESP32からsubmodule情報を取得して検証
        r2p2_cache = Pap::Env.get_cache_path('R2P2-ESP32',
                                             env_config['R2P2-ESP32']['commit'] + '-' + env_config['R2P2-ESP32']['timestamp'])

        _info, warnings = Pap::Env.traverse_submodules_and_validate(r2p2_cache)
        warnings.each { |w| puts "⚠️  #{w}" }

        puts "✓ Environment '#{env_name}' fetched successfully"
      end

      desc 'clean REPO', 'Delete all caches for specified repo'
      def clean(repo)
        cache_path = File.join(Pap::Env::CACHE_DIR, repo)
        if Dir.exist?(cache_path)
          puts "Removing cache: #{cache_path}"
          FileUtils.rm_rf(cache_path)
          puts '✓ Cache cleaned'
        else
          puts "Cache not found: #{cache_path}"
        end
      end

      desc 'prune', 'Delete caches not referenced by any environment'
      def prune
        puts 'Pruning unused cache...'
        data = Pap::Env.load_env_file
        used_commits = Set.new

        # 使用中のコミットを収集
        (data['environments'] || {}).each do |_env_name, env_config|
          %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
            info = env_config[repo]
            next if info.nil?

            used_commits << (info['commit'] + '-' + info['timestamp'])
          end
        end

        # キャッシュディレクトリをスキャン
        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          repo_cache_dir = File.join(Pap::Env::CACHE_DIR, repo)
          next unless Dir.exist?(repo_cache_dir)

          Dir.entries(repo_cache_dir).each do |entry|
            next if ['.', '..'].include?(entry)

            if used_commits.include?(entry)
              puts "  Keep: #{repo}/#{entry}"
            else
              cache_path = File.join(repo_cache_dir, entry)
              puts "  Remove: #{repo}/#{entry}"
              FileUtils.rm_rf(cache_path)
            end
          end
        end

        puts '✓ Pruning completed'
      end
    end
  end
end
