require "fileutils"
require "yaml"
require "erb"

module Picotorokko
  # プロジェクト初期化ロジック（Thor依存なし）
  class ProjectInitializer
    # テンプレートファイルの場所
    TEMPLATES_DIR = File.expand_path("templates/project", __dir__)

    attr_reader :project_root, :project_name, :options

    def initialize(project_name = nil, options = {})
      @project_name = project_name
      @options = options
      @project_root = determine_project_root(project_name)
      @project_name ||= File.basename(project_root)
    end

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

      print_success_message
    end

    private

    def determine_project_root(name)
      base_path = options[:path] || Dir.pwd

      if name
        File.join(base_path, name)
      else
        base_path
      end
    end

    def validate_project_name!(name)
      return if /\A[a-zA-Z0-9_-]+\z/.match?(name)

      raise "Invalid project name: #{name}. Use alphanumeric characters, dashes, and underscores."
    end

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

    def prepare_variables
      author = options[:author] || detect_git_author
      now = Time.now

      {
        project_name: project_name,
        author: author,
        timestamp: now.strftime("%Y%m%d_%H%M%S"),
        created_at: now.strftime("%Y-%m-%d %H:%M:%S"),
        picotorokko_version: Picotorokko::VERSION
      }
    end

    def detect_git_author
      author = `git config user.name`.strip
      # Ensure encoding is UTF-8 to avoid ASCII issues
      author.force_encoding("UTF-8") if author.respond_to?(:force_encoding)
      author
    rescue StandardError
      nil
    end

    def render_templates(variables)
      # Template files to render with ERB
      erb_templates = [
        ".picoruby-env.yml.erb",
        ".gitignore",
        "Gemfile.erb",
        "README.md.erb",
        "CLAUDE.md.erb",
        "storage/home/app.rb"
      ]

      erb_templates.each do |template_file|
        render_template(template_file, variables)
      end
    end

    def render_template(template_file, variables)
      template_path = File.join(TEMPLATES_DIR, template_file)
      output_file = template_file.delete_suffix(".erb")
      output_path = File.join(project_root, output_file)

      unless File.exist?(template_path)
        puts "Warning: Template not found: #{template_path}"
        return
      end

      # Read and render template
      content = File.read(template_path)

      # Simple ERB-like rendering with instance variables
      content = render_erb(content, variables) if template_file.end_with?(".erb")

      # Write to output
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, content)
    end

    def render_erb(template_content, variables)
      # Use ERB with a custom context
      require "erb"

      context = ERBContext.new(variables)
      ERB.new(template_content).result(context.binding)
    rescue LoadError
      # Fallback: simple string interpolation
      result = template_content
      variables.each do |key, value|
        result = result.gsub(/<%= @#{key} %>/, value.to_s)
      end
      result
    end

    # Context object for ERB template rendering
    class ERBContext
      def initialize(variables)
        variables.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
        @binding = instance_eval { ::Kernel.binding }
      end

      def binding
        @binding
      end
    end

    def copy_template_files
      # Copy non-ERB template files (static files that don't need rendering)
      files_to_copy = [
        "patch/README.md",
        "storage/home/.gitkeep",
        "patch/R2P2-ESP32/.gitkeep",
        "patch/picoruby-esp32/.gitkeep",
        "patch/picoruby/.gitkeep",
        "ptrk_env/.gitkeep"
      ]

      files_to_copy.each do |file|
        source = File.join(TEMPLATES_DIR, file)
        destination = File.join(project_root, file)

        next unless File.exist?(source)

        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(source, destination)
      end
    end

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
