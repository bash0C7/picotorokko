require "thor"
require_relative "../project_initializer"

module Picotorokko
  module Commands
    # Project creation commands
    # Creates new PicoRuby projects with directory structure, templates, and configuration
    # @rbs < Thor
    class New < Thor
      # @rbs () -> bool
      def self.exit_on_failure?
        true
      end

      # Default action - called when just "ptrk new" is used
      default_task :create

      # Create new PicoRuby project with directory structure and configuration
      # @rbs (String | nil) -> void
      desc "[PROJECT_NAME]", "Create a new PicoRuby project"
      option :path, type: :string, desc: "Create project in specified directory"
      option :author, type: :string, desc: "Set author name"
      option :"with-ci", type: :boolean, desc: "Copy GitHub Actions workflow"
      def create(project_name = nil)
        if project_name.nil?
          warn_missing_project_name
          return
        end

        initializer = Picotorokko::ProjectInitializer.new(project_name, options)
        initializer.initialize_project
      end

      private

      # @rbs () -> void
      def warn_missing_project_name
        puts "Error: PROJECT_NAME is required"
        puts ""
        puts "Usage: ptrk new PROJECT_NAME [OPTIONS]"
        puts ""
        puts "Examples:"
        puts "  ptrk new my-app"
        puts "  ptrk new my-app --with-ci"
        puts "  ptrk new my-app --author 'Your Name' --path /path/to/projects"
        puts ""
        puts "To create additional mrbgems, use: ptrk mrbgems generate NAME"
        puts "For more information: ptrk new help"
      end
    end
  end
end
