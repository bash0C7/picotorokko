require "thor"
require_relative "../project_initializer"

module Picotorokko
  module Commands
    # Project initialization commands
    # Creates new PicoRuby projects with directory structure, templates, and configuration
    # @rbs < Thor
    class Init < Thor
      # @rbs () -> bool
      def self.exit_on_failure?
        true
      end

      # Default action - called when just "ptrk init" is used
      default_task :create

      # Initialize new PicoRuby project with directory structure and configuration
      # @rbs (String | nil) -> void
      desc "[PROJECT_NAME]", "Initialize a new PicoRuby project"
      option :path, type: :string, desc: "Create project in specified directory"
      option :author, type: :string, desc: "Set author name"
      option :"with-ci", type: :boolean, desc: "Copy GitHub Actions workflow"
      option :"with-mrbgem", type: :array, desc: "Initialize with mrbgems"
      def create(project_name = nil)
        initializer = Picotorokko::ProjectInitializer.new(project_name, options)
        initializer.initialize_project
      end
    end
  end
end
