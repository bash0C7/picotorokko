
require 'thor'

module Pra
  module Commands
    # ESP32デバイス操作コマンド群（R2P2-ESP32タスク委譲）
    class Device < Thor
      def self.exit_on_failure?
        true
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

      desc 'build [ENV_NAME]', 'Build firmware for ESP32'
      def build(env_name = 'current')
        puts "Building: #{env_name}"
        delegate_to_r2p2('build', env_name)
        puts '✓ Build completed'
      end

      desc 'setup_esp32 [ENV_NAME]', 'Setup ESP32 build environment'
      def setup_esp32(env_name = 'current')
        puts "Setting up ESP32: #{env_name}"
        delegate_to_r2p2('setup_esp32', env_name)
        puts '✓ ESP32 setup completed'
      end

      # 明示的に定義されていないコマンドをRakeタスクに透過的に委譲
      def method_missing(method_name, *args)
        # Thorの内部メソッド呼び出しは無視
        return super if method_name.to_s.start_with?('_')

        env_name = args.first || 'current'
        puts "Delegating to R2P2-ESP32 task: #{method_name}"
        delegate_to_r2p2(method_name.to_s, env_name)
      rescue
        # Rakeタスクが存在しない場合など
        raise Thor::UndefinedCommandError, "Could not find command or R2P2-ESP32 task: #{method_name}"
      end

      def respond_to_missing?(method_name, include_private = false)
        # Thorの内部メソッド以外は全てR2P2タスクとして扱う可能性がある
        !method_name.to_s.start_with?('_') || super
      end

      private

      # R2P2-ESP32のRakefileにタスクを委譲
      def delegate_to_r2p2(command, env_name)
        # currentの場合はsymlinkから実環境名を取得
        if env_name == 'current'
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          if File.symlink?(current_link)
            current = Pra::Env.get_current_env
            env_name = current if current
          else
            raise "Error: No current environment set. Use 'pra env set ENV_NAME' first"
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

        r2p2_path = File.join(build_path, 'R2P2-ESP32')
        raise 'Error: R2P2-ESP32 not found in build environment' unless Dir.exist?(r2p2_path)

        # ESP-IDF環境でR2P2-ESP32のrakeタスクを実行
        Pra::Env.execute_with_esp_env("rake #{command}", r2p2_path)
      end
    end
  end
end
