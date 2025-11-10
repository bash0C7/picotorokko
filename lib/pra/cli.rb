
require 'thor'
require_relative 'version'
require_relative 'env'
require_relative 'commands/env'
require_relative 'commands/cache'
require_relative 'commands/build'
require_relative 'commands/patch'
require_relative 'commands/device'
require_relative 'commands/ci'
require_relative 'commands/mrbgems'
require_relative 'commands/rubocop'

module Pra
  # ptrkコマンドのCLIエントリーポイント
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    # サブコマンド登録
    desc 'env SUBCOMMAND ...ARGS', 'Environment management commands'
    subcommand 'env', Pra::Commands::Env

    desc 'mrbgems SUBCOMMAND ...ARGS', 'Application-specific mrbgem management'
    subcommand 'mrbgems', Pra::Commands::Mrbgems

    desc 'device SUBCOMMAND ...ARGS', 'ESP32 device operation commands'
    subcommand 'device', Pra::Commands::Device

    desc 'rubocop SUBCOMMAND ...ARGS', 'RuboCop configuration for PicoRuby development'
    subcommand 'rubocop', Pra::Commands::Rubocop

    # バージョン表示
    desc 'version', 'Show pra version'
    def version
      puts "pra version #{Pra::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
