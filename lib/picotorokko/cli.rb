require "thor"
require_relative "version"
require_relative "env"
require_relative "commands/env"
require_relative "commands/device"
require_relative "commands/mrbgems"
require_relative "commands/rubocop"

module Picotorokko
  # ptrkコマンドのCLIエントリーポイント
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    # サブコマンド登録
    desc "env SUBCOMMAND ...ARGS", "Environment management commands"
    subcommand "env", Picotorokko::Commands::Env

    desc "mrbgems SUBCOMMAND ...ARGS", "Application-specific mrbgem management"
    subcommand "mrbgems", Picotorokko::Commands::Mrbgems

    desc "device SUBCOMMAND ...ARGS", "ESP32 device operation commands"
    subcommand "device", Picotorokko::Commands::Device

    desc "rubocop SUBCOMMAND ...ARGS", "RuboCop configuration for PicoRuby development"
    subcommand "rubocop", Picotorokko::Commands::Rubocop

    # バージョン表示
    desc "version", "Show picotorokko version"
    def version
      puts "picotorokko version #{Picotorokko::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
