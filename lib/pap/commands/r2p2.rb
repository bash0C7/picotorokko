
require 'thor'

module Pap
  module Commands
    # R2P2-ESP32タスク委譲コマンド群
    class R2P2 < Thor
      def self.exit_on_failure?
        true
      end

      desc 'build [ENV_NAME]', 'Build R2P2-ESP32 firmware'
      def build(env_name = 'current')
        puts "Building: #{env_name}"
        delegate_to_r2p2('build', env_name)
        puts '✓ Build completed'
      end

      desc 'flash [ENV_NAME]', 'Flash firmware to ESP32'
      def flash(env_name = 'current')
        puts "Flashing: #{env_name}"
        delegate_to_r2p2('flash', env_name)
        puts '✓ Flash completed'
      end

      desc 'monitor [ENV_NAME]', 'Monitor ESP32 serial output'
      def monitor(env_name = 'current')
        puts "Monitoring: #{env_name}"
        puts '(Press Ctrl+C to exit)'
        delegate_to_r2p2('monitor', env_name)
      end

      private

      # R2P2-ESP32のRakefileにタスクを委譲
      def delegate_to_r2p2(command, env_name)
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

        r2p2_hash = env_config['R2P2-ESP32']['commit'] + '-' + env_config['R2P2-ESP32']['timestamp']
        esp32_hash = env_config['picoruby-esp32']['commit'] + '-' + env_config['picoruby-esp32']['timestamp']
        picoruby_hash = env_config['picoruby']['commit'] + '-' + env_config['picoruby']['timestamp']
        env_hash = Pap::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)

        build_path = Pap::Env.get_build_path(env_hash)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        r2p2_path = File.join(build_path, 'R2P2-ESP32')
        raise 'Error: R2P2-ESP32 not found in build environment' unless Dir.exist?(r2p2_path)

        # ESP-IDF環境でR2P2-ESP32のrakeタスクを実行
        Pap::Env.execute_with_esp_env("rake #{command}", r2p2_path)
      end
    end
  end
end
