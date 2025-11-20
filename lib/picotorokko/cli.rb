# rbs_inline: enabled

require "thor"
require_relative "version"
require_relative "env"
require_relative "commands/env"
require_relative "commands/device"
require_relative "commands/new"
require_relative "commands/mrbgems"
require_relative "commands/rubocop"

module Picotorokko
  # PicoRuby/mRuby ESP32 development tool CLI entry point
  # Handles subcommand routing for environment, device, mrbgems, and RuboCop operations
  # @rbs < Thor
  class CLI < Thor
    # @rbs () -> bool
    def self.exit_on_failure?
      true
    end

    # Project creation commands
    # Creates new PicoRuby projects with directory structure and configuration
    desc "new SUBCOMMAND ...ARGS", "Project creation commands"
    subcommand "new", Picotorokko::Commands::New

    # Environment management commands
    # Provides commands for managing PicoRuby build environments (latest, stable, etc.)
    desc "env SUBCOMMAND ...ARGS", "Environment management commands"
    subcommand "env", Picotorokko::Commands::Env

    # Application-specific mrbgem management
    # Allows users to configure and manage custom mrbgems for their projects
    desc "mrbgems SUBCOMMAND ...ARGS", "Application-specific mrbgem management"
    subcommand "mrbgems", Picotorokko::Commands::Mrbgems

    # ESP32 device operation commands
    # Handles device flashing, monitoring, building, and other device-specific operations
    desc "device SUBCOMMAND ...ARGS", "ESP32 device operation commands"
    subcommand "device", Picotorokko::Commands::Device

    # RuboCop configuration for PicoRuby development
    # Provides setup and validation for RuboCop configurations in PicoRuby projects
    desc "rubocop SUBCOMMAND ...ARGS", "RuboCop configuration for PicoRuby development"
    subcommand "rubocop", Picotorokko::Commands::Rubocop

    # Display picotorokko version
    # @rbs () -> void
    desc "version", "Show picotorokko version"
    def version
      puts "picotorokko version #{Picotorokko::VERSION}"
    end
    map %w[--version -v] => :version
  end
end
