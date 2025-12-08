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

    def generate_wrapper_function(class_name, method)
      func_name = "m5unified_#{class_name.downcase}_#{method[:name]}"
      return_type = method[:return_type] == "bool" ? "int" : method[:return_type]
      params = if method[:parameters].empty?
                 "void"
               else
                 method[:parameters].map do |p|
                   "#{p[:type]} #{p[:name]}"
                 end.join(", ")
               end

      content = "#{return_type} #{func_name}(#{params}) {\n"
      api_call = "M5.#{class_name}.#{method[:name]}"
      param_names = method[:parameters].map { |p| p[:name] }.join(", ")
      api_call += "(#{param_names})" unless param_names.empty?

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
