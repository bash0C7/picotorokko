# frozen_string_literal: true

begin
  require "ffi/clang"
  LIBCLANG_AVAILABLE = true
rescue LoadError
  LIBCLANG_AVAILABLE = false
end

module M5LibGen
  # Parses C++ header files using libclang AST
  class LibClangParser
    class ParseError < StandardError; end

    attr_reader :header_path

    def initialize(header_path, include_paths: [])
      @header_path = header_path
      @include_paths = include_paths

      raise ParseError, "Header file does not exist: #{header_path}" unless File.exist?(header_path)

      if LIBCLANG_AVAILABLE
        initialize_with_libclang
      else
        initialize_with_fallback
      end
    end

    # Extract all class definitions from header file
    def extract_classes
      if LIBCLANG_AVAILABLE
        extract_classes_with_libclang
      else
        extract_classes_with_fallback
      end
    end

    # Extract all enum definitions from header file
    def extract_enums
      if LIBCLANG_AVAILABLE
        extract_enums_with_libclang
      else
        extract_enums_with_fallback
      end
    end

    private

    def initialize_with_libclang
      @index = FFI::Clang::Index.new
      args = ["-x", "c++", "-std=c++17"]
      @include_paths.each { |path| args << "-I#{path}" }
      @translation_unit = @index.parse_translation_unit(@header_path, args)
    end

    def initialize_with_fallback
      @content = File.read(@header_path, encoding: "UTF-8")
    end

    def extract_classes_with_libclang
      classes = []
      extract_classes_recursive(@translation_unit.cursor, classes)
      classes
    end

    def extract_classes_recursive(cursor, classes)
      visit_children(cursor) do |child|
        case child.kind
        when :cursor_class_decl, :cursor_struct_decl
          # Found a class/struct - extract it
          class_info = {
            name: child.spelling,
            methods: extract_methods_from_class(child),
            enums: extract_enums_from_class(child)
          }
          classes << class_info
        when :cursor_namespace
          # Found a namespace - recurse into it
          extract_classes_recursive(child, classes)
        end
      end
    end

    def extract_enums_with_libclang
      enums = []
      cursor = @translation_unit.cursor

      visit_children(cursor) do |child|
        next unless child.kind == :cursor_enum_decl

        enum_info = {
          name: child.spelling,
          values: extract_enum_values(child),
          is_scoped: child.enum_scoped?
        }
        enums << enum_info
      end

      enums
    end

    def extract_enums_from_class(class_cursor)
      enums = []

      visit_children(class_cursor) do |child|
        next unless child.kind == :cursor_enum_decl

        enum_info = {
          name: child.spelling,
          values: extract_enum_values(child),
          is_scoped: child.enum_scoped?
        }
        enums << enum_info
      end

      enums
    end

    def extract_enum_values(enum_cursor)
      values = []

      visit_children(enum_cursor) do |child|
        next unless child.kind == :cursor_enum_constant_decl

        values << {
          name: child.spelling,
          value: child.enum_constant_value
        }
      end

      values
    end

    def extract_methods_from_class(class_cursor)
      methods = []

      visit_children(class_cursor) do |child|
        next unless child.kind == :cursor_cxx_method

        # Skip private/protected methods (only extract public)
        next unless %i[public invalid].include?(child.access_specifier)

        method_info = {
          name: child.spelling,
          return_type: child.result_type.spelling,
          parameters: extract_parameters_from_method(child),
          is_static: child.static_method?,
          is_const: child.const_qualified?,
          is_virtual: child.virtual_method?
        }
        methods << method_info
      end

      methods
    end

    def extract_parameters_from_method(method_cursor)
      parameters = []

      method_cursor.num_arguments.times do |i|
        param = method_cursor.argument(i)
        parameters << {
          type: param.type.spelling,
          name: param.spelling
        }
      end

      parameters
    end

    def visit_children(cursor)
      cursor.visit_children do |child, _parent|
        yield(child)
        :continue
      end
    end

    # Fallback implementation using regex (basic)
    def extract_classes_with_fallback
      classes = []

      # Match class/struct declarations with balanced braces
      # Support inheritance and newlines: class Name : public Base \n {
      class_start_pattern = /(?:class|struct)\s+(\w+)(?:\s*:\s*public\s+\w+)?[^{;]*?\{/m
      @content.scan(class_start_pattern).each do |class_name_match|
        class_name = class_name_match[0]
        # Find the start position of this class
        start_pos = @content.index(/(?:class|struct)\s+#{Regexp.escape(class_name)}\b/)
        next unless start_pos

        # Find the matching opening brace
        brace_start = @content.index("{", start_pos)
        next unless brace_start

        class_body = extract_balanced_braces(@content, brace_start)
        next unless class_body

        methods = extract_methods_from_body_fallback(class_body)
        enums = extract_enums_from_body_fallback(class_body)
        classes << {
          name: class_name,
          methods: methods,
          enums: enums
        }
      end

      classes
    end

    # Extract content between balanced braces { ... }
    def extract_balanced_braces(content, start_pos)
      brace_count = 0
      i = start_pos
      body_start = nil

      while i < content.length
        char = content[i]

        if char == "{"
          brace_count += 1
          body_start = i + 1 if brace_count == 1
        elsif char == "}"
          brace_count -= 1
          return content[body_start...i] if brace_count.zero?
        end

        i += 1
      end

      nil
    end

    def extract_enums_with_fallback
      enums = []

      # Match enum declarations: enum [class] Name { VALUES };
      enum_pattern = /enum\s+(?:class\s+)?(\w+)\s*\{([^}]*)\}/m
      @content.scan(enum_pattern) do |enum_name, enum_body|
        is_scoped = @content.include?("enum class #{enum_name}")
        values = extract_enum_values_fallback(enum_body)
        enums << {
          name: enum_name,
          values: values,
          is_scoped: is_scoped
        }
      end

      enums
    end

    def extract_enums_from_body_fallback(body)
      enums = []

      # Match enum declarations within class body
      enum_pattern = /enum\s+(?:class\s+)?(\w+)\s*\{([^}]*)\}/m
      body.scan(enum_pattern) do |enum_name, enum_body|
        is_scoped = body.include?("enum class #{enum_name}")
        values = extract_enum_values_fallback(enum_body)
        enums << {
          name: enum_name,
          values: values,
          is_scoped: is_scoped
        }
      end

      enums
    end

    def extract_enum_values_fallback(enum_body)
      values = []
      # Match: NAME [= VALUE]
      enum_body.scan(/(\w+)(?:\s*=\s*([^,}]+))?/) do |name, value|
        next if name.empty?

        values << {
          name: name,
          value: value&.strip
        }
      end
      values
    end

    def extract_methods_from_body_fallback(class_body)
      methods = []

      # Remove preprocessor directives to avoid false matches (keep method declarations)
      clean_body = class_body.dup
      clean_body.gsub!(/^\s*#\s*(if|ifdef|ifndef|elif|else|endif|define|undef|include|pragma).*$/, "")

      # Match method declarations: [static] [virtual] return_type method_name(params) [const];
      # Enhanced pattern to support:
      # - Reference types: Type&
      # - Pointer types: Type*
      # - Template types: std::vector<int>
      # - Multi-word types: unsigned int, const char*
      # - Namespace-qualified types: std::string, m5gfx::point_t
      decl_pattern = /(?:(static)\s+)?(?:(virtual)\s+)?((?:const\s+)?(?:unsigned\s+|signed\s+)?\w+(?:::\w+)*(?:\s*<[^>]+>)?(?:\s*[*&])?)\s+(\w+)\s*\(([^)]*)\)\s*(const)?\s*;/

      clean_body.scan(decl_pattern) do |static_kw, virtual_kw, return_type, method_name, params_str, const_kw|
        next if return_type.strip.empty?
        next if preprocessor_keyword?(return_type)

        parameters = extract_parameters_fallback(params_str)
        methods << {
          name: method_name,
          return_type: return_type.strip,
          parameters: parameters,
          is_static: !static_kw.nil?,
          is_const: !const_kw.nil?,
          is_virtual: !virtual_kw.nil?
        }
      end

      # Match inline method definitions: [static] [virtual] return_type method_name(params) [const] { body }
      inline_pattern = /(?:(static)\s+)?(?:(virtual)\s+)?((?:const\s+)?(?:unsigned\s+|signed\s+)?\w+(?:::\w+)*(?:\s*<[^>]+>)?(?:\s*[*&])?)\s+(\w+)\s*\(([^)]*)\)\s*(const)?\s*\{/m

      clean_body.scan(inline_pattern) do |static_kw, virtual_kw, return_type, method_name, params_str, const_kw|
        next if return_type.strip.empty?
        next if preprocessor_keyword?(return_type)

        parameters = extract_parameters_fallback(params_str)
        methods << {
          name: method_name,
          return_type: return_type.strip,
          parameters: parameters,
          is_static: !static_kw.nil?,
          is_const: !const_kw.nil?,
          is_virtual: !virtual_kw.nil?
        }
      end

      methods
    end

    def preprocessor_keyword?(text)
      # Check if text looks like a preprocessor keyword
      text.strip.match?(/^(if|ifdef|ifndef|else|elif|endif|define|undef|include|pragma|return)$/)
    end

    def extract_parameters_fallback(params_str)
      parameters = []

      # Split by comma for multiple parameters
      params_str.split(",").each do |param|
        param = param.strip
        next if param.empty?
        # Skip "void" parameter - it means no parameters
        next if param == "void"
        # Skip varargs "..." - not supported in mrubyc bindings
        next if param == "..."

        # Extract type and name: "int x" => type: "int", name: "x"
        parts = param.split(/\s+/)
        if parts.length >= 2
          parameters << {
            type: parts[0...-1].join(" "), # Support multi-word types like "unsigned int"
            name: parts[-1]
          }
        elsif parts.length == 1
          # Single word parameter (type only)
          parameters << {
            type: parts[0],
            name: parts[0]
          }
        end
      end

      parameters
    end
  end
end
