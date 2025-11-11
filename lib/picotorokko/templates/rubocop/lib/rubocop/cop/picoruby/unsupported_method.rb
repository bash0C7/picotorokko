# frozen_string_literal: true

module RuboCop
  module Cop
    module PicoRuby
      # Detects methods that are not supported in PicoRuby
      #
      # CRuby has many methods that PicoRuby doesn't implement due to memory
      # constraints. This cop warns when unsupported methods are used on core
      # class instances.
      #
      # @example
      #   # bad
      #   str = "hello"
      #   str.unicode_normalize  # Not supported in PicoRuby
      #   str.gsub!(/l/, 'L')    # In-place methods often not supported
      #
      #   arr = [1, 2, 2, 3]
      #   arr.combination(2)     # Enumerable methods may not be fully implemented
      #
      #   # good
      #   str = "hello"
      #   str.upcase             # Supported method
      #   str.size               # Supported method
      #
      #   arr = [1, 2, 3]
      #   arr.each { |x| puts x } # Supported enumerable method
      #
      # @see https://picoruby.org for PicoRuby documentation
      class UnsupportedMethod < Base
        MSG = 'Method `%<class>s#%<method>s` may not be supported in PicoRuby. ' \
              'Verify documentation or disable with `# rubocop:disable PicoRuby/UnsupportedMethod`'

        SETUP_MSG = 'PicoRuby method database not found. ' \
                    "Run 'pra rubocop update' to generate it."

        # Literal type to class name mapping
        LITERAL_TYPES = {
          array: 'Array',
          str: 'String',
          hash: 'Hash',
          int: 'Integer',
          float: 'Float',
          sym: 'Symbol'
        }.freeze

        # Performance optimization: only check these methods that are likely to be unsupported
        RESTRICT_ON_SEND = %i[
          gsub! upcase! downcase! sub! subb! tr_s! squeeze! strip! lstrip! rstrip!
          unicode_normalize encode convert combination permutation repeated_permutation
          downto upto
        ].freeze

        def on_send(node)
          return unless @unsupported_methods

          receiver_type = infer_receiver_type(node.receiver)
          return unless receiver_type
          return unless core_class?(receiver_type)

          method_name = node.method_name.to_s
          return unless unsupported?(receiver_type, method_name)

          add_offense(
            node.loc.selector,
            message: format(MSG, class: receiver_type, method: method_name)
          )
        end

        private

        def setup_offenses
          super
          load_unsupported_methods
        end

        def load_unsupported_methods
          data_path = find_data_file('picoruby_unsupported_methods.json')
          return false unless data_path && File.exist?(data_path)

          content = File.read(data_path)
          @unsupported_methods = JSON.parse(content)
          true
        rescue StandardError => e
          puts "Warning: #{SETUP_MSG} (#{e.class})"
          false
        end

        def find_data_file(filename)
          # Check multiple possible locations
          possible_paths = [
            # Current directory structure
            File.join(Dir.pwd, 'data', filename),
            # Relative to script directory
            File.expand_path("../../../data/#{filename}", __dir__),
            # Fallback
            File.join(Dir.pwd, filename)
          ]

          possible_paths.find { |path| File.exist?(path) }
        end

        def infer_receiver_type(receiver_node)
          return nil unless receiver_node

          return LITERAL_TYPES[receiver_node.type] if LITERAL_TYPES.key?(receiver_node.type)
          return infer_send_type(receiver_node) if receiver_node.type == :send
          return receiver_node.const_name.to_s if receiver_node.type == :const

          nil
        end

        def infer_send_type(receiver_node)
          # Handle method calls: String.new.upcase
          return unless receiver_node.method_name == :new && receiver_node.receiver&.const_type?

          receiver_node.receiver.const_name.to_s
        end

        def core_class?(class_name)
          %w[Array String Hash Integer Float Symbol Range Regexp].include?(class_name)
        end

        def unsupported?(class_name, method_name)
          return false unless @unsupported_methods
          return false unless @unsupported_methods[class_name]

          class_data = @unsupported_methods[class_name]
          class_data['instance'].include?(method_name) ||
            class_data['class'].include?(method_name)
        end
      end
    end
  end
end
