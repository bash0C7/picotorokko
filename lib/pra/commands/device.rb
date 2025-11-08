
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

      desc 'help [ENV_NAME]', 'Display available Rake tasks in R2P2-ESP32'
      def help(env_name = 'current')
        actual_env = resolve_env_name(env_name)
        r2p2_path = validate_and_get_r2p2_path(actual_env)

        puts "Available tasks in R2P2-ESP32 for environment: #{actual_env}\n\n"
        # ESP-IDF環境でrake -Tを実行して、利用可能なタスク一覧を表示
        Pra::Env.execute_with_esp_env('rake -T', r2p2_path)
      end

      # 明示的に定義されていないコマンドをRakeタスクに透過的に委譲
      def method_missing(method_name, *args)
        # Thorの内部メソッド呼び出しは無視
        return super if method_name.to_s.start_with?('_')

        env_name = args.first || 'current'
        puts "Delegating to R2P2-ESP32 task: #{method_name}"
        delegate_to_r2p2(method_name.to_s, env_name)
      rescue StandardError
        # Rakeタスクが存在しない場合など
        raise Thor::UndefinedCommandError.new(
          method_name.to_s,
          self.class.all_commands.keys,
          self.class.namespace
        )
      end

      def respond_to_missing?(method_name, include_private = false)
        # Thorの内部メソッド以外は全てR2P2タスクとして扱う可能性がある
        !method_name.to_s.start_with?('_') || super
      end

      private

      # R2P2-ESP32のRakefileにタスクを委譲
      def delegate_to_r2p2(command, env_name)
        actual_env = resolve_env_name(env_name)
        r2p2_path = validate_and_get_r2p2_path(actual_env)

        # ESP-IDF環境でR2P2-ESP32のrakeタスクを実行
        Pra::Env.execute_with_esp_env("rake #{command}", r2p2_path)
      end

      # 環境名を解決（currentの場合は実環境名に変換）
      def resolve_env_name(env_name)
        return env_name unless env_name == 'current'

        current_link = File.join(Pra::Env::BUILD_DIR, 'current')
        raise "Error: No current environment set. Use 'pra env set ENV_NAME' first" unless File.symlink?(current_link)

        current = Pra::Env.get_current_env
        current || env_name
      end

      # 環境を検証してR2P2パスを取得
      def validate_and_get_r2p2_path(env_name)
        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        hashes = Pra::Env.compute_env_hash(env_name)
        raise "Error: Failed to compute environment hash for '#{env_name}'" if hashes.nil?

        _r2p2_hash, _esp32_hash, _picoruby_hash, env_hash = hashes
        build_path = Pra::Env.get_build_path(env_hash)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        r2p2_path = File.join(build_path, 'R2P2-ESP32')
        raise 'Error: R2P2-ESP32 not found in build environment' unless Dir.exist?(r2p2_path)

        r2p2_path
      end
    end
  end
end
