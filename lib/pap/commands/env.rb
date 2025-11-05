
require 'thor'

module Pap
  module Commands
    # 環境管理コマンド群
    class Env < Thor
      def self.exit_on_failure?
        true
      end

      desc 'show', 'Display current environment configuration'
      def show
        current = Pap::Env.get_current_env
        if current.nil?
          puts 'Current environment: (not set)'
          puts "Run 'pap env set ENV_NAME' to set an environment"
        else
          env_config = Pap::Env.get_environment(current)
          if env_config.nil?
            puts "Error: Environment '#{current}' not found in .picoruby-env.yml"
          else
            puts "Current environment: #{current}"

            # Symlink情報
            current_link = File.join(Pap::Env::BUILD_DIR, 'current')
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

      desc 'set ENV_NAME', 'Switch to specified environment'
      def set(env_name)
        env_config = Pap::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        # ビルド環境が存在するか確認
        r2p2_hash = env_config['R2P2-ESP32']['commit'] + '-' + env_config['R2P2-ESP32']['timestamp']
        esp32_hash = env_config['picoruby-esp32']['commit'] + '-' + env_config['picoruby-esp32']['timestamp']
        picoruby_hash = env_config['picoruby']['commit'] + '-' + env_config['picoruby']['timestamp']
        env_hash = Pap::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
        build_path = Pap::Env.get_build_path(env_hash)

        if Dir.exist?(build_path)
          puts "Switching to environment: #{env_name}"
          current_link = File.join(Pap::Env::BUILD_DIR, 'current')
          Pap::Env.create_symlink(File.basename(build_path), current_link)
          Pap::Env.set_current_env(env_name)
          puts "✓ Switched to #{env_name}"
        else
          puts "Error: Build environment not found at #{build_path}"
          puts "Run 'pap build setup #{env_name}' first"
        end
      end

      desc 'latest', 'Fetch latest versions and switch to them'
      def latest
        puts 'Fetching latest commits from GitHub...'
        raise 'Not yet implemented - use cache fetch ENV_NAME instead'
      end
    end
  end
end
