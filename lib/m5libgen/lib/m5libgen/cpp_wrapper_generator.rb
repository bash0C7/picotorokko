# frozen_string_literal: true

require_relative "naming_helper"

module M5LibGen
  # Generates C++ extern "C" wrapper functions
  class CppWrapperGenerator
    include NamingHelper

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

    def generate_wrapper_function(class_name, method)
      # Generate unique function name based on parameter types
      func_name = generate_unique_function_name(class_name, method)
      return_type = method[:return_type] == "bool" ? "int" : method[:return_type]
      params = generate_sanitized_params(method)

      content = "#{return_type} #{func_name}(#{params}) {\n"
      api_call = "M5.#{class_name}.#{method[:name]}"
      # Use sanitized parameter names in API call
      param_names = get_sanitized_param_names(method)
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
