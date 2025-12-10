# frozen_string_literal: true

module M5LibGen
  # Generates C++ extern "C" wrapper functions
  class CppWrapperGenerator
    def initialize(cpp_data)
      @cpp_data = cpp_data
    end

    def generate
      content = "#include <M5Unified.h>\n\n"
      content += "extern \"C\" {\n\n"
      @cpp_data.each do |klass|
        klass[:methods].each do |method|
          content += generate_wrapper_function(klass[:name], method)
        end
      end
      content += "} // extern \"C\"\n"
      content
    end

    private

    # Sanitize parameter name to valid C++ identifier
    def sanitize_parameter_name(name, index)
      # Check if name is invalid (nil, empty, or contains invalid characters)
      if name.nil? || name.empty? || name.match?(/[.\->\s\[\]()]/)
        "param_#{index}"
      else
        name
      end
    end

    # Normalize C++ type name for use in function naming
    def normalize_type_for_naming(cpp_type)
      # Remove const, &, *, spaces and convert to simple identifier
      normalized = cpp_type.strip
      normalized = normalized.gsub(/^const\s+/, "")      # Remove const prefix
      normalized = normalized.gsub(/[&*\s]+$/, "")       # Remove &, *, spaces at end
      normalized = normalized.gsub(/\s+/, "")            # Remove all spaces
      normalized = normalized.gsub(/::|<|>|,/, "_")      # Replace ::, <, >, , with _
      normalized = normalized.gsub(/[^a-zA-Z0-9_]/, "")  # Remove non-alphanumeric
      normalized.downcase
    end

    # Generate unique function name based on class, method, and parameter types
    def generate_unique_function_name(class_name, method)
      base_name = "m5unified_#{class_name.downcase}_#{method[:name].downcase}"

      if method[:parameters].empty?
        return "#{base_name}_void"
      end

      # Generate type signature from parameter types
      type_signature = method[:parameters].map do |p|
        normalize_type_for_naming(p[:type])
      end.join("_")

      "#{base_name}_#{type_signature}"
    end

    def generate_wrapper_function(class_name, method)
      # Generate unique function name based on parameter types
      func_name = generate_unique_function_name(class_name, method)
      return_type = method[:return_type] == "bool" ? "int" : method[:return_type]
      params = if method[:parameters].empty?
                 "void"
               else
                 method[:parameters].map.with_index do |p, idx|
                   sanitized_name = sanitize_parameter_name(p[:name], idx)
                   "#{p[:type]} #{sanitized_name}"
                 end.join(", ")
               end

      content = "#{return_type} #{func_name}(#{params}) {\n"
      api_call = "M5.#{class_name}.#{method[:name]}"
      # Use sanitized parameter names in API call
      param_names = method[:parameters].map.with_index do |p, idx|
        sanitize_parameter_name(p[:name], idx)
      end.join(", ")
      # Always add parentheses for method calls
      api_call += "(#{param_names})"

      content += if return_type == "int" && method[:return_type] == "bool"
                   "  return #{api_call} ? 1 : 0;\n"
                 elsif method[:return_type] == "void"
                   "  #{api_call};\n"
                 else
                   "  return #{api_call};\n"
                 end

      content += "}\n\n"
      content
    end
  end
end
