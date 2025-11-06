
require 'thor'
require_relative 'version'
require_relative 'env'
require_relative 'commands/env'
require_relative 'commands/cache'
require_relative 'commands/build'
require_relative 'commands/patch'
require_relative 'commands/device'
require_relative 'commands/ci'

module Pra
  # praコマンドのCLIエントリーポイント
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    # サブコマンド登録
    desc 'env SUBCOMMAND ...ARGS', 'Environment management commands'
    subcommand 'env', Pra::Commands::Env

    desc 'cache SUBCOMMAND ...ARGS', 'Cache management commands'
    subcommand 'cache', Pra::Commands::Cache

    desc 'build SUBCOMMAND ...ARGS', 'Build environment management commands'
    subcommand 'build', Pra::Commands::Build

    desc 'patch SUBCOMMAND ...ARGS', 'Patch management commands'
    subcommand 'patch', Pra::Commands::Patch

    desc 'ci SUBCOMMAND ...ARGS', 'CI/CD configuration commands'
    subcommand 'ci', Pra::Commands::Ci

    desc 'device SUBCOMMAND ...ARGS', 'ESP32 device operation commands'
    subcommand 'device', Pra::Commands::Device

    # バージョン表示
    desc 'version', 'Show pra version'
    def version
      puts "pra version #{Pra::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
