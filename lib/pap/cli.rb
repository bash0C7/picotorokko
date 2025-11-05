# frozen_string_literal: true

require 'thor'
require_relative 'version'
require_relative 'env'
require_relative 'commands/env'
require_relative 'commands/cache'
require_relative 'commands/build'
require_relative 'commands/patch'
require_relative 'commands/r2p2'

module Pap
  # papコマンドのCLIエントリーポイント
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    # サブコマンド登録
    desc 'env SUBCOMMAND ...ARGS', 'Environment management commands'
    subcommand 'env', Pap::Commands::Env

    desc 'cache SUBCOMMAND ...ARGS', 'Cache management commands'
    subcommand 'cache', Pap::Commands::Cache

    desc 'build SUBCOMMAND ...ARGS', 'Build environment management commands'
    subcommand 'build', Pap::Commands::Build

    desc 'patch SUBCOMMAND ...ARGS', 'Patch management commands'
    subcommand 'patch', Pap::Commands::Patch

    # R2P2-ESP32タスク委譲（トップレベルコマンド）
    desc 'flash [ENV_NAME]', 'Flash firmware to ESP32 (delegates to R2P2-ESP32)'
    option :env, type: :string, default: 'current', aliases: '-e', desc: 'Environment name'
    def flash(env_name = nil)
      env_name ||= options[:env]
      Pap::Commands::R2P2.new.flash(env_name)
    end

    desc 'monitor [ENV_NAME]', 'Monitor ESP32 serial output (delegates to R2P2-ESP32)'
    option :env, type: :string, default: 'current', aliases: '-e', desc: 'Environment name'
    def monitor(env_name = nil)
      env_name ||= options[:env]
      Pap::Commands::R2P2.new.monitor(env_name)
    end

    # バージョン表示
    desc 'version', 'Show pap version'
    def version
      puts "pap version #{Pap::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
