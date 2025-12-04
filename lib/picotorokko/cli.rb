# rbs_inline: enabled

require "thor"
require_relative "version"
require_relative "env"
require_relative "commands/env"
require_relative "commands/device"
require_relative "commands/new"
require_relative "commands/mrbgems"
require_relative "commands/patch"
module Picotorokko
  # PicoRuby/mRuby ESP32 development tool CLI entry point
  # Handles subcommand routing for environment, device, and mrbgems operations
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

    # Patch management commands
    # Provides export, diff, and list operations for patches
    desc "patch SUBCOMMAND ...ARGS", "Patch management commands"
    subcommand "patch", Picotorokko::Commands::Patch

    # Display picotorokko version
    # @rbs () -> void
    desc "version", "Show picotorokko version"
    def version
      puts "picotorokko version #{Picotorokko::VERSION}"
    end
    map %w[--version -v] => :version

    # Show help and documentation references
    # @rbs () -> void
    desc "help [COMMAND]", "Show help for ptrk commands"
    def help(command = nil)
      super
      return if command

      puts "\n📚 Documentation:"
      puts "  For usage guides and tutorials: https://github.com/bash0C7/picotorokko/tree/main/user-guide"
      puts "  For command specifications: user-guide/SPECIFICATION.md"
      puts "  For CI/CD workflows: user-guide/CI_CD_GUIDE.md"
      puts "  For mrbgems management: user-guide/MRBGEMS_GUIDE.md"
      puts "\n💡 Quick Start:"
      puts "  1. Create a project: ptrk new my-project"
      puts "  2. Setup environment: ptrk env set --latest"
      puts "  3. Build firmware: ptrk device build"
      puts "  4. Flash to device: ptrk device flash"
    end
  end
end
