# frozen_string_literal: true

require "fileutils"
require_relative "naming_helper"

module M5LibGen
  # Generates complete mrbgem directory structure and files
  class MrbgemGenerator
    include NamingHelper

    attr_reader :output_path

    def initialize(output_path)
      @output_path = output_path
    end

    def generate(cpp_data)
      # Filter out unsupported methods
      filtered_data, stats = filter_unsupported_methods(cpp_data)

      create_structure
      render_mrbgem_rake
      render_c_bindings(filtered_data)
      render_ruby_lib(filtered_data)
      render_readme(filtered_data)
      render_cpp_wrapper(filtered_data)
      render_cmake

      # Return statistics about filtering
      stats
    end

    private

    # Filter out methods with unsupported types
    def filter_unsupported_methods(cpp_data)
      filtered_count = 0
      generated_count = 0

      filtered_data = cpp_data.map do |klass|
        original_methods = klass[:methods]
        supported_methods = original_methods.select do |method|
          # Check return type
          if TypeMapper.unsupported_type?(method[:return_type])
            filtered_count += 1
            next false
          end

          # Check parameter types
          has_unsupported_param = method[:parameters].any? do |param|
            TypeMapper.unsupported_type?(param[:type])
          end

          if has_unsupported_param
            filtered_count += 1
            false
          else
            generated_count += 1
            true
          end
        end

        klass.merge(methods: supported_methods)
      end

      stats = {
        filtered_count: filtered_count,
        generated_count: generated_count
      }

      [filtered_data, stats]
    end

    def create_structure
      FileUtils.mkdir_p(@output_path)
      FileUtils.mkdir_p(File.join(@output_path, "mrblib"))
      FileUtils.mkdir_p(File.join(@output_path, "src"))
      FileUtils.mkdir_p(File.join(@output_path, "ports", "esp32"))
    end

    def render_mrbgem_rake
      content = <<~RUBY
        MRuby::Gem::Specification.new('picoruby-m5unified') do |spec|
          spec.license = 'MIT'
          spec.author  = 'M5LibGen'
          spec.summary = 'M5Unified bindings for PicoRuby'
        end
      RUBY
      File.write(File.join(@output_path, "mrbgem.rake"), content)
    end

    def render_c_bindings(cpp_data)
      content = "/* M5Unified C Bindings for PicoRuby */\n"
      content += "#include <mrubyc.h>\n\n"
      content += generate_forward_declarations(cpp_data)
      content += generate_function_wrappers(cpp_data)
      content += generate_gem_init(cpp_data)
      File.write(File.join(@output_path, "src", "m5unified.c"), content)
    end

    def generate_forward_declarations(cpp_data)
      content = "/* Forward declarations */\n"
      cpp_data.each do |klass|
        content += "static mrbc_class *c_#{klass[:name]};\n"
      end
      content += "\n/* Extern function declarations */\n"
      cpp_data.each do |klass|
        klass[:methods].each do |method|
          # Use NamingHelper for consistent naming with C++ wrapper
          func_name = generate_unique_function_name(klass[:name], method)
          # Convert bool return type to int, keep others as-is
          return_type = method[:return_type] == "bool" ? "int" : method[:return_type]
          # Build parameter list with sanitized names
          params = generate_sanitized_params(method)
          content += "extern #{return_type} #{func_name}(#{params});\n"
        end
      end
      "#{content}\n"
    end

    def generate_function_wrappers(cpp_data)
      content = "/* Method wrappers */\n"
      cpp_data.each do |klass|
        klass[:methods].each do |method|
          content += generate_method_wrapper(klass[:name], method)
        end
      end
      "#{content}\n"
    end

    def generate_method_wrapper(class_name, method)
      # Use NamingHelper for consistent naming
      param_count = method[:parameters].length
      func_name = "mrbc_m5_#{method[:name].downcase}_#{param_count}"
      extern_func = generate_unique_function_name(class_name, method)

      content = "static void #{func_name}(mrbc_vm *vm, mrbc_value *v, int argc) {\n"

      # Extract parameters from mruby stack with type-aware conversion
      method[:parameters].each_with_index do |param, idx|
        arg_index = idx + 1
        param_name = sanitize_parameter_name(param[:name], idx)
        param_c_type = TypeMapper.get_c_type_for_param(param[:type])
        get_macro = TypeMapper.get_arg_macro(param[:type])

        content += "  #{param_c_type} #{param_name} = #{get_macro}(#{arg_index});\n"
      end

      # Build extern function call with sanitized parameter names
      param_names = get_sanitized_param_names(method)

      # Type-aware return value handling
      if method[:return_type] == "void"
        # Void return - just call and return nil
        content += "  #{extern_func}(#{param_names});\n"
        content += "  SET_RETURN(mrbc_nil_value());\n"
      elsif method[:return_type] == "bool"
        # Bool return - call, store result, convert to bool
        content += "  int result = #{extern_func}(#{param_names});\n"
        content += "  SET_BOOL_RETURN(result);\n"
      else
        # Use TypeMapper to determine correct return handling
        return_c_type = TypeMapper.get_c_type_for_param(method[:return_type])
        set_macro = TypeMapper.set_return_macro(method[:return_type])
        content += "  #{return_c_type} result = #{extern_func}(#{param_names});\n"
        content += "  #{set_macro}(result);\n"
      end

      content += "}\n\n"
      content
    end

    def generate_gem_init(cpp_data)
      content = "void mrbc_mrbgem_picoruby_m5unified_gem_init(mrbc_vm *vm) {\n"
      cpp_data.each do |klass|
        content += "  c_#{klass[:name]} = mrbc_define_class(vm, \"#{klass[:name]}\", mrbc_class_object);\n"
        klass[:methods].each do |method|
          # Add parameter count to handle overloading
          param_count = method[:parameters].length
          method_func = "mrbc_m5_#{method[:name].downcase}_#{param_count}"
          content += "  mrbc_define_method(vm, c_#{klass[:name]}, \"#{method[:name]}\", #{method_func});\n"
        end
      end
      "#{content}}\n"
    end

    def render_ruby_lib(cpp_data)
      content = "# M5Unified Ruby bindings\n"
      content += "# Auto-generated by M5LibGen\n\n"
      cpp_data.each { |klass| content += "# Class: #{klass[:name]}\n" }
      File.write(File.join(@output_path, "mrblib", "m5unified.rb"), content)
    end

    def render_readme(cpp_data)
      content = "# picoruby-m5unified\n\n"
      content += "M5Unified bindings for PicoRuby.\n\n"
      content += "## Classes\n\n"
      cpp_data.each { |klass| content += "- #{klass[:name]}\n" }
      content += "\n## License\n\nMIT\n"
      File.write(File.join(@output_path, "README.md"), content)
    end

    def render_cpp_wrapper(cpp_data)
      generator = CppWrapperGenerator.new(cpp_data)
      content = generator.generate
      File.write(File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp"), content)
    end

    def render_cmake
      generator = CMakeGenerator.new
      content = generator.generate
      File.write(File.join(@output_path, "CMakeLists.txt"), content)
    end
  end
end
