require "fileutils"
require "yaml"
require_relative "template/engine"

module Picotorokko
  # Project initialization logic independent of Thor
  # Handles directory structure creation, template rendering, and project setup
  class ProjectInitializer
    # Template files directory path
    TEMPLATES_DIR = File.expand_path("templates/project", __dir__)

    attr_reader :project_root, :project_name, :options

    # @rbs (String | nil, Hash[Symbol, untyped]) -> void
    def initialize(project_name = nil, options = {})
      @project_name = project_name
      @options = options
      @project_root = determine_project_root(project_name)
      @project_name ||= File.basename(project_root)
    end

    # @rbs () -> void
    def initialize_project
      # Validate project name
      validate_project_name!(project_name)

      # Create all directories
      create_directories

      # Prepare template variables
      variables = prepare_variables

      # Render and copy template files
      render_templates(variables)

      # Copy non-template files
      copy_template_files

      # Generate mrbgems if requested
      generate_mrbgems

      print_success_message
    end

    private

    # @rbs (String | nil) -> String
    def determine_project_root(name)
      base_path = options[:path] || Dir.pwd

      if name
        File.join(base_path, name)
      else
        base_path
      end
    end

    # @rbs (String) -> void
    def validate_project_name!(name)
      return if /\A[a-zA-Z0-9_-]+\z/.match?(name)

      raise "Invalid project name: #{name}. Use alphanumeric characters, dashes, and underscores."
    end

    # @rbs () -> void
    def create_directories
      directories = [
        "storage/home",
        "patch/R2P2-ESP32",
        "patch/picoruby-esp32",
        "patch/picoruby",
        "ptrk_env",
        ".github/workflows"
      ]

      directories.each do |dir|
        FileUtils.mkdir_p(File.join(project_root, dir))
      end
    end

    # @rbs () -> Hash[Symbol, (String | nil)]
    def prepare_variables
      author = options[:author] || detect_git_author || ""
      now = Time.now

      {
        project_name: project_name,
        author: author,
        timestamp: now.strftime("%Y%m%d_%H%M%S"),
        created_at: now.strftime("%Y-%m-%d %H:%M:%S"),
        picotorokko_version: Picotorokko::VERSION
      }
    end

    # @rbs () -> (String | nil)
    def detect_git_author
      author = `git config user.name`.strip
      # Ensure encoding is UTF-8 to avoid ASCII issues
      author.force_encoding("UTF-8") if author.respond_to?(:force_encoding)
      author
    rescue StandardError
      nil
    end

    # @rbs (Hash[Symbol, (String | nil)]) -> void
    def render_templates(variables)
      # Template files to render with Prism engine
      template_files = [
        ".picoruby-env.yml",
        ".gitignore",
        "Gemfile",
        "README.md",
        "CLAUDE.md",
        "storage/home/app.rb"
      ]

      template_files.each do |template_file|
        render_template(template_file, variables)
      end
    end

    # @rbs (String, Hash[Symbol, (String | nil)]) -> void
    def render_template(template_file, variables)
      template_path = File.join(TEMPLATES_DIR, template_file)
      output_path = File.join(project_root, template_file)

      unless File.exist?(template_path)
        puts "Warning: Template not found: #{template_path}"
        return
      end

      # Render template using Prism-based engine (supports .rb, .yml, .md, etc.)
      content = Picotorokko::Template::Engine.render(template_path, variables)

      # Write to output
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, content)
    end

    # @rbs () -> void
    def copy_template_files
      # Copy template files (static files that don't need rendering)
      files_to_copy = [
        "patch/README.md",
        "storage/home/.gitkeep",
        "patch/R2P2-ESP32/.gitkeep",
        "patch/picoruby-esp32/.gitkeep",
        "patch/picoruby/.gitkeep",
        "ptrk_env/.gitkeep"
      ]

      # Add GitHub Actions workflow if --with-ci is enabled
      files_to_copy << ".github/workflows/esp32-build.yml" if options[:with_ci] || options["with_ci"]

      files_to_copy.each do |file|
        source = File.join(TEMPLATES_DIR, file)
        destination = File.join(project_root, file)

        next unless File.exist?(source)

        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(source, destination)
      end
    end

    # @rbs () -> void
    def generate_mrbgems
      mrbgem_names = options[:with_mrbgem] || options["with_mrbgem"] || []
      return if mrbgem_names.empty?

      mrbgem_names.each do |name|
        generate_single_mrbgem(name)
      end
    end

    # @rbs (String) -> void
    def generate_single_mrbgem(name)
      mrbgem_dir = File.join(project_root, "mrbgems", name)
      FileUtils.mkdir_p(File.join(mrbgem_dir, "mrblib"))
      FileUtils.mkdir_p(File.join(mrbgem_dir, "src"))

      # Prepare template context
      c_prefix = name.downcase
      template_context = {
        mrbgem_name: name,
        class_name: name,
        c_prefix: c_prefix,
        author_name: options[:author] || detect_git_author || ""
      }

      # Render and write template files
      render_mrbgem_templates(mrbgem_dir, name, c_prefix, template_context)
    end

    # @rbs (String, String, String, Hash[Symbol, untyped]) -> void
    def render_mrbgem_templates(mrbgem_dir, _name, c_prefix, context)
      templates_dir = File.expand_path("templates/mrbgem_app", __dir__)

      templates = [
        { source: "mrbgem.rake.erb", dest: "mrbgem.rake" },
        { source: "README.md.erb", dest: "README.md" },
        { source: "mrblib/app.rb", dest: "mrblib/#{c_prefix}.rb" },
        { source: "src/app.c.erb", dest: "src/#{c_prefix}.c" }
      ]

      templates.each do |template|
        template_path = File.join(templates_dir, template[:source])
        output_path = File.join(mrbgem_dir, template[:dest])

        next unless File.exist?(template_path)

        content = Picotorokko::Template::Engine.render(template_path, context)
        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, content)
      end
    end

    # @rbs () -> void
    def print_success_message
      puts "* Created new PicoRuby project: #{project_name}"
      puts "  Location: #{project_root}"
      puts ""
      puts "Next steps:"
      puts "  1. cd #{project_name}" if project_name != File.basename(Dir.pwd)
      puts "  2. ptrk env set main --commit <hash>"
      puts "  3. ptrk build setup"
      puts "  4. cd build/current/R2P2-ESP32 && rake build"
    end
  end
end
