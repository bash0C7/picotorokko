require "English"
require "fileutils"
require "thor"

module Picotorokko
  module Commands
    # RuboCop configuration and method database management for PicoRuby development
    class Rubocop < Thor
      desc "setup", "Setup RuboCop configuration for PicoRuby development"
      long_desc <<~LONGDESC
        Sets up RuboCop configuration with PicoRuby custom cop.

        This command copies the RuboCop template to your project:
        - .rubocop.yml
        - lib/rubocop/cop/picoruby/unsupported_method.rb
        - scripts/update_methods.rb
        - data/README.md
        - README.md (setup guide)

        After setup, run 'pra rubocop update' to generate the method database.
      LONGDESC
      def setup
        source_dir = File.expand_path("../templates/rubocop", __dir__)
        target_dir = Dir.pwd

        copy_template_files(source_dir, target_dir)

        puts "\n✅ RuboCop configuration has been set up!"
        puts ""
        puts "Next steps:"
        puts "  1. Run: pra rubocop update"
        puts "     (generates method database from latest PicoRuby definitions)"
        puts ""
        puts "  2. Run: bundle exec rubocop"
        puts "     (checks your code)"
        puts ""
        puts "See README.md for more details."
      end

      desc "update", "Update PicoRuby method database"
      long_desc <<~LONGDESC
        Updates the PicoRuby method database using the latest definitions from
        picoruby.github.io.

        This will:
        1. Clone or pull picoruby.github.io
        2. Extract method definitions from RBS documentation
        3. Compare with CRuby to find unsupported methods
        4. Generate data/picoruby_supported_methods.json
        5. Generate data/picoruby_unsupported_methods.json

        Run this whenever:
        - Setting up for the first time (after 'pra rubocop setup')
        - PicoRuby has been updated with new methods
        - You want to refresh the method database
      LONGDESC
      def update
        script_path = File.join(Dir.pwd, "scripts", "update_methods.rb")

        unless File.exist?(script_path)
          puts "❌ Update script not found."
          puts ""
          puts "Please run 'pra rubocop setup' first to set up the RuboCop configuration."
          exit 1
        end

        puts "🚀 Running method database update..."
        puts ""

        # Execute the update script
        cmd = "ruby #{script_path}"
        success = system(cmd)

        return if success

        # Failure case
        exit_status = $CHILD_STATUS.exitstatus if $CHILD_STATUS
        raise "Command failed (exit status: #{exit_status || "unknown"}): #{cmd}"
      end

      private

      def copy_template_files(source, target)
        files_to_copy = [
          ".rubocop.yml",
          "lib",
          "scripts",
          "data",
          "README.md"
        ]

        files_to_copy.each do |file|
          source_path = File.join(source, file)
          target_path = File.join(target, file)

          if File.exist?(target_path)
            unless yes?("#{file} already exists. Overwrite? (y/N)")
              puts "⏭️  Skipped: #{file}"
              next
            end
            FileUtils.rm_rf(target_path)
          end

          if File.directory?(source_path)
            FileUtils.cp_r(source_path, target_path)
          else
            FileUtils.cp(source_path, target_path)
          end
          puts "✅ Copied: #{file}"
        end
      end
    end
  end
end
