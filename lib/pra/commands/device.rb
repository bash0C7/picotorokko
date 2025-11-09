
require 'thor'
require 'prism'

module Pra
  module Commands
    # ESP32デバイス操作コマンド群（R2P2-ESP32タスク委譲）
    class Device < Thor
      def self.exit_on_failure?
        true
      end

      desc 'flash [ENV_NAME]', 'Flash firmware to ESP32'
      def flash(env_name = 'current')
        actual_env = resolve_env_name(env_name)
        validate_and_get_r2p2_path(actual_env)

        puts "Flashing: #{actual_env}"
        delegate_to_r2p2('flash', env_name)
        puts '✓ Flash completed'
      end

      desc 'monitor [ENV_NAME]', 'Monitor ESP32 serial output'
      def monitor(env_name = 'current')
        actual_env = resolve_env_name(env_name)
        validate_and_get_r2p2_path(actual_env)

        puts "Monitoring: #{actual_env}"
        puts '(Press Ctrl+C to exit)'
        delegate_to_r2p2('monitor', env_name)
      end

      desc 'build [ENV_NAME]', 'Build firmware for ESP32'
      def build(env_name = 'current')
        actual_env = resolve_env_name(env_name)
        validate_and_get_r2p2_path(actual_env)

        puts "Building: #{actual_env}"
        delegate_to_r2p2('build', env_name)
        puts '✓ Build completed'
      end

      desc 'setup_esp32 [ENV_NAME]', 'Setup ESP32 build environment'
      def setup_esp32(env_name = 'current')
        actual_env = resolve_env_name(env_name)
        validate_and_get_r2p2_path(actual_env)

        puts "Setting up ESP32: #{actual_env}"
        delegate_to_r2p2('setup_esp32', env_name)
        puts '✓ ESP32 setup completed'
      end

      desc 'tasks [ENV_NAME]', 'Show available R2P2-ESP32 tasks'
      def tasks(env_name = 'current')
        actual_env = resolve_env_name(env_name)
        validate_and_get_r2p2_path(actual_env)

        show_available_tasks(env_name)
      end

      desc 'help [ENV_NAME]', 'Show available R2P2-ESP32 tasks (alias for tasks)'
      def help(env_name = 'current')
        tasks(env_name)
      end

      # 明示的に定義されていないコマンドをRakeタスクに透過的に委譲
      def method_missing(method_name, *args)
        # Thorの内部メソッド呼び出しは無視
        return super if method_name.to_s.start_with?('_')

        env_name = args.first || 'current'
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

      def respond_to_missing?(method_name, include_private = false)
        # Thorの内部メソッド以外は全てR2P2タスクとして扱う可能性がある
        !method_name.to_s.start_with?('_') || super
      end

      private

      # 利用可能なR2P2-ESP32タスクを表示
      def show_available_tasks(env_name)
        actual_env = resolve_env_name(env_name)
        r2p2_path = validate_and_get_r2p2_path(actual_env)

        puts "Available R2P2-ESP32 tasks for environment: #{actual_env}"
        puts "=" * 60
        Pra::Env.execute_with_esp_env('rake -T', r2p2_path)
      end

      # R2P2-ESP32のRakefileにタスクを委譲
      def delegate_to_r2p2(command, env_name)
        actual_env = resolve_env_name(env_name)
        r2p2_path = validate_and_get_r2p2_path(actual_env)

        # ESP-IDF環境でR2P2-ESP32のrakeタスクを実行
        Pra::Env.execute_with_esp_env("rake #{command}", r2p2_path)
      end

      # 環境名を解決（currentの場合は実環境名に変換）
      def resolve_env_name(env_name)
        return env_name unless env_name == 'current'

        current_link = File.join(Pra::Env::BUILD_DIR, 'current')
        raise "Error: No current environment set. Use 'pra env set ENV_NAME' first" unless File.symlink?(current_link)

        current = Pra::Env.get_current_env
        current || env_name
      end

      # 環境を検証してR2P2パスを取得
      def validate_and_get_r2p2_path(env_name)
        env_config = Pra::Env.get_environment(env_name)
        raise "Error: Environment '#{env_name}' not found" if env_config.nil?

        hashes = Pra::Env.compute_env_hash(env_name)
        raise "Error: Failed to compute environment hash for '#{env_name}'" if hashes.nil?

        _r2p2_hash, _esp32_hash, _picoruby_hash, env_hash = hashes
        build_path = Pra::Env.get_build_path(env_hash)
        raise "Error: Build environment not found: #{env_name}" unless Dir.exist?(build_path)

        r2p2_path = File.join(build_path, 'R2P2-ESP32')
        raise 'Error: R2P2-ESP32 not found in build environment' unless Dir.exist?(r2p2_path)

        r2p2_path
      end

      # Rakefileから利用可能なタスクを取得
      def available_rake_tasks(r2p2_path)
        rakefile_path = File.join(r2p2_path, 'Rakefile')
        return [] unless File.exist?(rakefile_path)

        source = File.read(rakefile_path)
        result = Prism.parse(source)

        extractor = RakeTaskExtractor.new
        result.value.accept(extractor)

        extractor.tasks.uniq.sort
      rescue StandardError => e
        warn "Warning: Failed to parse Rakefile: #{e.message}" if ENV['DEBUG']
        []
      end
    end

    # AST-based Rake task extractor for secure, static analysis
    class RakeTaskExtractor < Prism::Visitor
      attr_reader :tasks

      def initialize
        super
        @tasks = []
      end

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
      def handle_task_definition(node)
        return unless node.arguments&.arguments&.any?

        task_name = extract_task_name(node.arguments.arguments[0])
        @tasks << task_name if task_name
      end

      # Dynamic task generation: %w[...].each do |var| task "name_#{var}" end
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
      def extract_array_elements(array_node)
        array_node.elements.filter_map do |elem|
          elem.unescaped if elem.is_a?(Prism::StringNode)
        end
      end

      # Get block parameter name from |var| syntax
      def extract_block_parameter(block_node)
        params = block_node&.parameters&.parameters
        return unless params&.requireds&.any?

        params.requireds[0].name
      end

      # Find all task definitions within a block and extract their patterns
      def extract_task_patterns_from_block(block_node, param_name)
        body = block_node&.body&.body
        return [] unless body

        task_statements = body.select { |stmt| task_call?(stmt) }
        task_statements.filter_map { |stmt| extract_task_pattern(stmt.arguments.arguments[0], param_name) }
      end

      # Check if statement is a task() call with arguments
      def task_call?(stmt)
        stmt.is_a?(Prism::CallNode) && stmt.name == :task && stmt.arguments&.arguments&.any?
      end

      # Extract pattern from interpolated string like "setup_#{name}"
      # Returns array of { type: :string/:variable, value: ... } hashes
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
      def extract_embedded_variable(stmt_node, param_name)
        var = stmt_node.statements.body[0]
        return unless var.is_a?(Prism::LocalVariableReadNode)
        return unless var.name == param_name

        { type: :variable }
      end

      # Expand pattern by replacing :variable placeholders with actual values
      # Example: [{ type: :string, value: "setup_" }, { type: :variable }] + "esp32" → "setup_esp32"
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
