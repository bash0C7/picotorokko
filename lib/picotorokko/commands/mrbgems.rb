require "thor"
require "fileutils"

module Picotorokko
  module Commands
    # Application-specific mrbgem management commands
    # Provides utilities for creating and managing custom mrbgems for PicoRuby projects
    # Generates C/Ruby template files for new mrbgems
    # @rbs < Thor
    class Mrbgems < Thor
      # @rbs () -> bool
      def self.exit_on_failure?
        true
      end

      # Generate application-specific mrbgem template with scaffold files
      # @rbs (String) -> void
      desc "generate [NAME]", "Generate application-specific mrbgem template (default: App)"
      option :author, type: :string, desc: "Author name for the mrbgem"
      def generate(name = "App")
        mrbgem_dir = prepare_and_validate_directory(name)
        context = prepare_template_context(name)
        render_template_files(mrbgem_dir, context)
        print_success_message(name, context[:c_prefix])
      end

      private

      def prepare_and_validate_directory(name)
        mrbgem_dir = File.join(Dir.pwd, "mrbgems", name)
        raise "Error: Directory already exists: #{mrbgem_dir}" if Dir.exist?(mrbgem_dir)

        puts "Generating mrbgem template: #{name}"
        FileUtils.mkdir_p(File.join(mrbgem_dir, "mrblib"))
        FileUtils.mkdir_p(File.join(mrbgem_dir, "src"))
        puts "✓ Created directories"
        mrbgem_dir
      end

      def prepare_template_context(name)
        c_prefix = name.downcase
        author_name = options[:author] || `git config user.name`.strip || "Your Name"

        {
          mrbgem_name: name,
          class_name: name,
          c_prefix: c_prefix,
          author_name: author_name
        }
      end

      def render_template_files(mrbgem_dir, context)
        templates_dir = templates_directory
        template_files = build_template_file_map(mrbgem_dir, context[:c_prefix])

        template_files.each do |template_rel_path, output_path|
          template_path = File.join(templates_dir, template_rel_path)
          raise "Error: Template file not found: #{template_path}" unless File.exist?(template_path)

          render_single_template(template_path, output_path, context)
        end
      end

      def render_single_template(template_path, output_path, variables)
        rendered_content = Picotorokko::Template::Engine.render(template_path, variables)
        File.write(output_path, rendered_content, encoding: "UTF-8")
        puts "✓ Created: #{File.basename(output_path)}"
      end

      def build_template_file_map(mrbgem_dir, c_prefix)
        {
          "mrbgem.rake.erb" => File.join(mrbgem_dir, "mrbgem.rake"),
          "mrblib/app.rb" => File.join(mrbgem_dir, "mrblib", "#{c_prefix}.rb"),
          "src/app.c.erb" => File.join(mrbgem_dir, "src", "#{c_prefix}.c"),
          "README.md.erb" => File.join(mrbgem_dir, "README.md")
        }
      end

      def templates_directory
        gem_root = File.expand_path("../../../", __dir__)
        File.join(gem_root, "lib", "picotorokko", "templates", "mrbgem_app")
      end

      def print_success_message(name, c_prefix)
        puts "\n=== mrbgem Template Generated ==="
        puts "Location: mrbgems/#{name}/"
        puts "\nNext steps:"
        puts "  1. Edit the C extension: mrbgems/#{name}/src/#{c_prefix}.c"
        puts "  2. The mrbgem will be registered automatically during 'ptrk build setup'"
        puts "  3. Export patches to manage your changes: ptrk patch export <env>"
      end
    end
  end
end
