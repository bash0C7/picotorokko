# rbs_inline: enabled

require "shellwords"
require "thor"
require "prism"

module Picotorokko
  module Commands
    # ESP32 device operation commands
    # Delegates device operations (flash, monitor, build) to R2P2-ESP32 Rakefile
    # Provides abstraction for device-specific tasks
    # @rbs < Thor
    class Device < Thor
      # @rbs () -> bool
      def self.exit_on_failure?
        true
      end

      # Flash firmware to ESP32 device
      # @rbs () -> void
      desc "flash", "Flash firmware to ESP32"
      option :env, default: "current", desc: "Environment name"
      def flash
        env_name = options[:env]
        actual_env = resolve_env_name(env_name)
        validate_and_get_r2p2_path(actual_env)

        puts "Flashing: #{actual_env}"
        delegate_to_r2p2("flash", env_name)
        puts "\u2713 Flash completed"
      end

      # Monitor ESP32 serial output stream
      # @rbs () -> void
      desc "monitor", "Monitor ESP32 serial output"
      option :env, default: "current", desc: "Environment name"
      def monitor
        env_name = options[:env]
        actual_env = resolve_env_name(env_name)
        r2p2_path = validate_and_get_r2p2_path(actual_env)

        puts "To monitor ESP32 serial output, run:"
        puts ""
        puts "  pushd #{r2p2_path} && source ~/esp/esp-idf/export.sh && rake monitor ; popd"
        puts ""
        puts "(Press Ctrl+C to exit monitor)"
      end

      # Build firmware for ESP32
      # Automatically runs setup_esp32 on first build (when build/repos/esp32 doesn't exist)
      # @rbs () -> void
      desc "build", "Build firmware for ESP32"
      option :env, default: "current", desc: "Environment name"
      def build
        env_name = options[:env]
        actual_env = resolve_env_name(env_name)

        build_path = Picotorokko::Env.get_build_path(actual_env)
        r2p2_full_path = File.join(build_path, "R2P2-ESP32")
        setup_marker = File.join(r2p2_full_path, "build/repos/esp32")

        # Prepare build environment if it doesn't exist
        unless Dir.exist?(build_path)
          puts "Build environment not found, preparing..."
          prepare_build_environment(actual_env)
        end

        # Check if ESP32 setup is needed
        setup_required = !File.exist?(setup_marker)

        # Validate R2P2-ESP32 path (raises error if invalid)
        validate_and_get_r2p2_path(actual_env)

        # Apply Mrbgemfile if it exists
        apply_mrbgemfile_internal(actual_env)

        if setup_required
          puts "First build detected, running setup_esp32..."
          delegate_to_r2p2("setup_esp32", env_name)
        end

        puts "Building: #{actual_env}"
        delegate_to_r2p2("build", env_name)
        puts "\u2713 Build completed"
      end

      # Build, flash and monitor in sequence (default R2P2-ESP32 task)
      # Automatically runs setup_esp32 on first build (when build/repos/esp32 doesn't exist)
      # @rbs () -> void
      desc "all", "Build, flash and monitor (default rake task)"
      option :env, default: "current", desc: "Environment name"
      def all
        env_name = options[:env]
        actual_env = resolve_env_name(env_name)

        build_path = Picotorokko::Env.get_build_path(actual_env)
        r2p2_full_path = File.join(build_path, "R2P2-ESP32")
        setup_marker = File.join(r2p2_full_path, "build/repos/esp32")

        # Prepare build environment if it doesn't exist
        unless Dir.exist?(build_path)
          puts "Build environment not found, preparing..."
          prepare_build_environment(actual_env)
        end

        # Check if ESP32 setup is needed
        setup_required = !File.exist?(setup_marker)

        # Validate R2P2-ESP32 path (raises error if invalid)
        validate_and_get_r2p2_path(actual_env)

        # Apply Mrbgemfile if it exists
        apply_mrbgemfile_internal(actual_env)

        if setup_required
          puts "First build detected, running setup_esp32..."
          delegate_to_r2p2("setup_esp32", env_name)
        end

        puts "Running build → flash → monitor: #{actual_env}"
        delegate_to_r2p2("", env_name)
        puts "\u2713 Completed build → flash → monitor"
      end

      # Prepare build environment without resetting existing changes
      # @rbs () -> void
      desc "prepare", "Prepare build environment (preserves existing changes)"
      option :env, default: "current", desc: "Environment name"
      def prepare
        env_name = options[:env]
        actual_env = resolve_env_name(env_name)

        build_path = Picotorokko::Env.get_build_path(actual_env)

        if Dir.exist?(build_path)
          puts "Build environment already exists: #{actual_env}"
          puts "  Location: #{build_path}"
          puts "  (Use 'ptrk device reset' to force reset)"
          return
        end

        puts "Preparing build environment: #{actual_env}"
        prepare_build_environment(actual_env)
        puts "\u2713 Build environment prepared: #{build_path}"
      end

      # Setup ESP32 build environment (idf setup)
      # @rbs () -> void
      desc "setup_esp32", "Setup ESP32 build environment"
      option :env, default: "current", desc: "Environment name"
      def setup_esp32
        env_name = options[:env]
        actual_env = resolve_env_name(env_name)
        validate_and_get_r2p2_path(actual_env)

        puts "Setting up ESP32: #{actual_env}"
        delegate_to_r2p2("setup_esp32", env_name)
        puts "\u2713 ESP32 setup completed"
      end

      # Show available R2P2-ESP32 Rake tasks
      # @rbs () -> void
      desc "tasks", "Show available R2P2-ESP32 tasks"
      option :env, default: "current", desc: "Environment name"
      def tasks
        env_name = options[:env]
        actual_env = resolve_env_name(env_name)
        validate_and_get_r2p2_path(actual_env)

        show_available_tasks(env_name)
      end

      # Show available tasks (alias for tasks command)
      # @rbs () -> void
      desc "help", "Show available R2P2-ESP32 tasks (alias for tasks)"
      option :env, default: "current", desc: "Environment name"
      def help
        tasks
      end

      # Transparently delegate undefined commands to R2P2-ESP32 Rakefile
      #
      # Implements Ruby's method_missing to provide transparent delegation of unknown
      # commands to the R2P2-ESP32 Rakefile. This allows the ptrk device command to
      # expose any Rake task defined in R2P2-ESP32 without hardcoding them.
      #
      # **Security**: Uses whitelist validation by parsing the Rakefile AST with Prism
      # to ensure only legitimate Rake tasks can be executed. Prevents arbitrary command
      # injection through the command name.
      #
      # **Workflow**:
      # 1. Parse --env option from args (default: 'current')
      # 2. Resolve environment name and validate R2P2 build path exists
      # 3. Extract available Rake tasks from R2P2-ESP32/Rakefile via AST parsing
      # 4. Validate requested task is in the whitelist (if available)
      # 5. Delegate to R2P2-ESP32 Rakefile via rake command
      #
      # **Example**:
      #   ptrk device flash --env development
      #   ptrk device monitor --env stable-2024-11
      #   ptrk device custom_task --env latest
      #
      # @param method_name [Symbol] The task name to delegate
      # @param args [Array] Arguments including --env option
      # @raise [Thor::UndefinedCommandError] If task not found in whitelist
      # @rbs (*untyped) -> void
      def method_missing(method_name, *args)
        # Ignore Thor internal method calls
        return super if method_name.to_s.start_with?("_")

        # Parse --env option from args
        env_name = parse_env_from_args(args) || "current"
        actual_env = resolve_env_name(env_name)
        r2p2_path = validate_and_get_r2p2_path(actual_env)

        # Get whitelist of available tasks
        available_tasks = available_rake_tasks(r2p2_path)
        task_name = method_name.to_s

        # If whitelist exists and task not in it, reject
        unless available_tasks.empty? || available_tasks.include?(task_name)
          raise Thor::UndefinedCommandError.new(
            task_name,
            self.class.all_commands.keys + available_tasks,
            self.class.namespace
          )
        end

        puts "Delegating to R2P2-ESP32 task: #{task_name}"
        delegate_to_r2p2(task_name, env_name)
      rescue Errno::ENOENT, RuntimeError
        raise Thor::UndefinedCommandError.new(
          method_name.to_s,
          self.class.all_commands.keys,
          self.class.namespace
        )
      end

      # @rbs (Symbol, bool) -> bool
      def respond_to_missing?(method_name, include_private = false)
        # Thorの内部メソッド以外は全てR2P2タスクとして扱う可能性がある
        !method_name.to_s.start_with?("_") || super
      end

      private

      # @rbs (String) -> String
      def validate_env_value(value)
        raise "Error: --env option requires a non-empty environment name" if value.empty?

        value
      end

      # --env option を args から抽出
      # @rbs (Array[untyped]) -> (String | nil)
      def parse_env_from_args(args)
        return nil if args.empty?

        args.each_with_index do |arg, index|
          return validate_env_value(args[index + 1]) if arg == "--env" && args[index + 1]
          return validate_env_value(arg.split("=", 2)[1]) if arg.start_with?("--env=")
        end

        nil
      end

      # Internal helper: Apply Mrbgemfile if it exists
      # Reads Mrbgemfile and applies mrbgems to build_config files
      # @rbs (String) -> void
      def apply_mrbgemfile_internal(env_name)
        mrbgemfile_path = File.join(Picotorokko::Env.project_root, "Mrbgemfile")
        return unless File.exist?(mrbgemfile_path)

        mrbgemfile_content = File.read(mrbgemfile_path)
        actual_env = resolve_env_name(env_name)
        r2p2_path = validate_and_get_r2p2_path(actual_env)

        MrbgemfileApplier.apply(mrbgemfile_content, r2p2_path)
      end

      # 利用可能なR2P2-ESP32タスクを表示
      # @rbs (String) -> void
      def show_available_tasks(env_name)
        actual_env = resolve_env_name(env_name)
        r2p2_path = validate_and_get_r2p2_path(actual_env)

        puts "Available R2P2-ESP32 tasks for environment: #{actual_env}"
        puts "=" * 60
        rake_cmd = build_rake_command(r2p2_path, "-T")
        Picotorokko::Env.execute_with_esp_env(rake_cmd, r2p2_path)
      end

      # R2P2-ESP32のRakefileにタスクを委譲
      # @rbs (String, String) -> void
      def delegate_to_r2p2(command, env_name)
        actual_env = resolve_env_name(env_name)
        r2p2_path = validate_and_get_r2p2_path(actual_env)

        # Build appropriate rake command (with or without bundler)
        rake_cmd = build_rake_command(r2p2_path, command)

        # ESP-IDF環境でR2P2-ESP32のrakeタスクを実行
        Picotorokko::Env.execute_with_esp_env(rake_cmd, r2p2_path)
      end

      # 環境名を解決（currentの場合は実環境名に変換）
      # @rbs (String) -> String
      def resolve_env_name(env_name)
        return env_name unless env_name == "current"

        current = Picotorokko::Env.get_current_env
        if current.nil?
          raise "Error: No current environment set. Use 'ptrk device <command> --env <name>' to specify an environment"
        end

        current
      end

      # 環境を検証してR2P2パスを取得
      # @rbs (String) -> String
      def validate_and_get_r2p2_path(env_name)
        env_config = Picotorokko::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        build_path = Picotorokko::Env.get_build_path(env_name)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        # R2P2-ESP32 is in subdirectory under build_path
        # setup_build_environment copies .ptrk_env/{env}/ to .ptrk_build/{env}/
        # which includes R2P2-ESP32/ subdirectory
        r2p2_path = File.join(build_path, "R2P2-ESP32")
        raise "Error: R2P2-ESP32 not found in build environment" unless Dir.exist?(r2p2_path)

        r2p2_path
      end

      # Rakefileから利用可能なタスクを取得
      # @rbs (String) -> Array[String]
      def available_rake_tasks(r2p2_path)
        rakefile_path = File.join(r2p2_path, "Rakefile")
        return [] unless File.exist?(rakefile_path)

        source = File.read(rakefile_path)
        result = Prism.parse(source)

        extractor = RakeTaskExtractor.new
        result.value.accept(extractor)

        extractor.tasks.uniq.sort
      rescue StandardError => e
        warn "Warning: Failed to parse Rakefile: #{e.message}" if ENV["DEBUG"]
        []
      end

      # Build rake command - always uses rake directly without bundle exec
      # R2P2-ESP32 project may have Gemfile without rake dependency
      # Empty task_name runs default rake task
      # @rbs (String, String) -> String
      def build_rake_command(_r2p2_path, task_name)
        if task_name.to_s.empty?
          "rake"
        else
          "rake #{task_name}"
        end
      end

      # Prepare build environment without resetting existing changes
      # Creates .build directory, applies patches, copies storage/mrbgems
      # @rbs (String) -> void
      def prepare_build_environment(env_name)
        env_config = Picotorokko::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        env_path = File.join(Picotorokko::Env::ENV_DIR, env_name)
        build_path = Picotorokko::Env.get_build_path(env_name)
        r2p2_path = File.join(build_path, "R2P2-ESP32")

        raise "Error: Environment directory not found: #{env_path}" unless Dir.exist?(env_path)

        # Copy entire env to build
        puts "  Copying environment to build directory..."
        FileUtils.mkdir_p(File.dirname(build_path))
        FileUtils.cp_r(env_path, build_path)
        puts "  \u2713 Environment copied to #{build_path}"

        # Apply patches
        apply_patches_to_build(r2p2_path)

        # Copy storage/home
        copy_storage_home(r2p2_path)

        # Copy mrbgems
        copy_mrbgems(r2p2_path)
      end

      # Apply patches from patch/ directory to build
      # @rbs (String) -> void
      def apply_patches_to_build(r2p2_path)
        # Apply patches from .ptrk_env/patch/ (stored patches)
        stored_patch_dir = Picotorokko::Env.patch_dir
        apply_patches_from_dir(stored_patch_dir, r2p2_path) if Dir.exist?(stored_patch_dir)

        # Apply patches from project root patch/ directory
        project_patch_dir = File.join(Picotorokko::Env.project_root, "patch")
        apply_patches_from_dir(project_patch_dir, r2p2_path) if Dir.exist?(project_patch_dir)

        puts "  \u2713 Applied patches"
      end

      # Apply patches from a specific directory
      # @rbs (String, String) -> void
      def apply_patches_from_dir(patch_dir, r2p2_path)
        %w[R2P2-ESP32 picoruby-esp32 picoruby].each do |repo|
          apply_repo_patches(patch_dir, repo, r2p2_path)
        end
      end

      # Apply patches for a single repository
      # @rbs (String, String, String) -> void
      def apply_repo_patches(patch_dir, repo, r2p2_path)
        repo_patch_dir = File.join(patch_dir, repo)
        return unless Dir.exist?(repo_patch_dir)

        target_path = repo_target_path(repo, r2p2_path)
        return unless target_path && Dir.exist?(target_path)

        copy_patch_files(repo_patch_dir, target_path)
      end

      # Get target path for repository
      # @rbs (String, String) -> (String | nil)
      def repo_target_path(repo, r2p2_path)
        case repo
        when "R2P2-ESP32"
          r2p2_path
        when "picoruby-esp32"
          File.join(r2p2_path, "components", "picoruby-esp32")
        when "picoruby"
          File.join(r2p2_path, "components", "picoruby-esp32", "picoruby")
        end
      end

      # Copy patch files to target directory
      # @rbs (String, String) -> void
      def copy_patch_files(repo_patch_dir, target_path)
        Dir.glob("#{repo_patch_dir}/**/*").each do |patch_file|
          next if File.directory?(patch_file)

          relative_path = patch_file.sub("#{repo_patch_dir}/", "")
          target_file = File.join(target_path, relative_path)

          FileUtils.mkdir_p(File.dirname(target_file))
          FileUtils.cp(patch_file, target_file)
        end
      end

      # Copy storage/home to build
      # @rbs (String) -> void
      def copy_storage_home(r2p2_path)
        storage_home = Picotorokko::Env.storage_home
        return unless Dir.exist?(storage_home)

        target_storage = File.join(r2p2_path, "storage", "home")
        FileUtils.mkdir_p(target_storage)
        FileUtils.cp_r(Dir.glob("#{storage_home}/*"), target_storage)
        puts "  \u2713 Copied storage/home"
      end

      # Copy mrbgems to build
      # @rbs (String) -> void
      def copy_mrbgems(r2p2_path)
        mrbgems_dir = File.join(Picotorokko::Env.project_root, "mrbgems")
        return unless Dir.exist?(mrbgems_dir)

        target_mrbgems = File.join(r2p2_path, "components", "picoruby-esp32", "picoruby", "mrbgems")
        FileUtils.mkdir_p(target_mrbgems)

        Dir.glob("#{mrbgems_dir}/*").each do |gem_dir|
          next unless File.directory?(gem_dir)

          gem_name = File.basename(gem_dir)
          FileUtils.cp_r(gem_dir, File.join(target_mrbgems, gem_name))
        end

        puts "  \u2713 Copied mrbgems"
      end
    end

    # AST-based Rake task extractor for secure, static analysis
    #
    # **Purpose**: Safely extract Rake task names from a Rakefile without executing it.
    # Uses the Prism Ruby parser to analyze the AST (Abstract Syntax Tree) instead of
    # relying on `rake -T`, which requires the full Rakefile to be executable.
    #
    # **Security Model**: Static AST analysis prevents any code execution, making it safe
    # to analyze untrusted or partially-working Rakefiles. No shell escape needed.
    #
    # **Supported Task Patterns**:
    # 1. Direct task definition:
    #    ```ruby
    #    task :build
    #    task "flash"
    #    ```
    #
    # 2. Dynamically generated tasks:
    #    ```ruby
    #    %w[esp32 rp2040].each do |target|
    #      task "setup_#{target}"
    #    end
    #    # Expands to: setup_esp32, setup_rp2040
    #    ```
    #
    # **Limitations**: Does not support:
    # - Rake::TaskLib subclasses (require execution)
    # - Tasks defined in included files
    # - Complex string interpolation beyond simple variable expansion
    #
    # **Algorithm**:
    # 1. Visit all call nodes in AST
    # 2. Find `task()` calls with task name argument
    # 3. For block iteration patterns, extract array elements and expand with variable
    # 4. Return sorted, unique task names
    #
    # @example Usage in device.rb:available_rake_tasks
    #   result = Prism.parse(File.read("Rakefile"))
    #   extractor = RakeTaskExtractor.new
    #   result.value.accept(extractor)
    #   extractor.tasks  # => ["build", "flash", "monitor", ...]
    #
    class RakeTaskExtractor < Prism::Visitor
      attr_reader :tasks

      # Initialize task extractor with empty task list
      # @rbs () -> void
      def initialize
        super
        @tasks = []
      end

      # @rbs (Prism::CallNode) -> void
      def visit_call_node(node)
        case node.name
        when :task
          handle_task_definition(node)
        when :each
          handle_each_block_with_task_generation(node)
        end

        super
      end

      private

      # Standard task definition: task :name or task "name"
      # @rbs (Prism::CallNode) -> void
      def handle_task_definition(node)
        return unless node.arguments&.arguments&.any?

        task_name = extract_task_name(node.arguments.arguments[0])
        @tasks << task_name if task_name
      end

      # Dynamic task generation: %w[...].each do |var| task "name_#{var}" end
      # @rbs (Prism::CallNode) -> void
      def handle_each_block_with_task_generation(node)
        # Only handle array literals (not constants, method calls)
        return unless node.receiver.is_a?(Prism::ArrayNode)

        # Extract array elements
        array_elements = extract_array_elements(node.receiver)
        return if array_elements.empty?

        # Get block parameter name
        block_param_name = extract_block_parameter(node.block)
        return unless block_param_name

        # Find task definitions inside block
        task_patterns = extract_task_patterns_from_block(node.block, block_param_name)

        # Expand patterns for each array element
        task_patterns.each do |pattern|
          array_elements.each do |element|
            expanded_name = expand_pattern(pattern, element)
            @tasks << expanded_name
          end
        end
      end

      # Extract string values from array literal
      # @rbs (Prism::ArrayNode) -> Array[String]
      def extract_array_elements(array_node)
        array_node.elements.filter_map do |elem|
          elem.unescaped if elem.is_a?(Prism::StringNode)
        end
      end

      # Get block parameter name from |var| syntax
      # @rbs (Prism::BlockNode | nil) -> (Symbol | nil)
      def extract_block_parameter(block_node)
        params = block_node&.parameters&.parameters
        return unless params&.requireds&.any?

        params.requireds[0].name
      end

      # Find all task definitions within a block and extract their patterns
      # @rbs (Prism::BlockNode | nil, Symbol) -> Array[Array[Hash[Symbol, (String | Symbol)]]]
      def extract_task_patterns_from_block(block_node, param_name)
        body = block_node&.body&.body
        return [] unless body

        task_statements = body.select { |stmt| task_call?(stmt) }
        task_statements.filter_map { |stmt| extract_task_pattern(stmt.arguments.arguments[0], param_name) }
      end

      # Check if statement is a task() call with arguments
      # @rbs (untyped) -> bool
      def task_call?(stmt)
        stmt.is_a?(Prism::CallNode) && stmt.name == :task && stmt.arguments&.arguments&.any?
      end

      # Extract pattern from interpolated string like "setup_#{name}"
      # Returns array of { type: :string/:variable, value: ... } hashes
      # @rbs (untyped, Symbol) -> (Array[Hash[Symbol, (String | Symbol)]] | nil)
      def extract_task_pattern(arg_node, param_name)
        return unless arg_node.is_a?(Prism::InterpolatedStringNode)

        parts = arg_node.parts.filter_map do |part|
          case part
          when Prism::StringNode
            { type: :string, value: part.unescaped }
          when Prism::EmbeddedStatementsNode
            extract_embedded_variable(part, param_name)
          end
        end
        parts unless parts.empty?
      end

      # Extract variable from embedded statement if it matches the block parameter
      # @rbs (Prism::EmbeddedStatementsNode, Symbol) -> (Hash[Symbol, untyped] | nil)
      def extract_embedded_variable(stmt_node, param_name)
        var = stmt_node.statements.body[0]
        return unless var.is_a?(Prism::LocalVariableReadNode)
        return unless var.name == param_name

        { type: :variable }
      end

      # Expand pattern by replacing :variable placeholders with actual values
      # Example: [{ type: :string, value: "setup_" }, { type: :variable }] + "esp32" → "setup_esp32"
      # @rbs (Array[Hash[Symbol, untyped]], String) -> String
      def expand_pattern(pattern, value)
        pattern.map do |part|
          case part[:type]
          when :string
            part[:value]
          when :variable
            value
          end
        end.join
      end

      # Extract simple task name from string or symbol node
      # @rbs (untyped) -> (String | nil)
      def extract_task_name(arg_node)
        case arg_node
        when Prism::StringNode, Prism::SymbolNode
          arg_node.unescaped
        when Prism::InterpolatedStringNode
          # Cannot expand runtime interpolation, skip
          nil
        end
      end
    end
  end
end
