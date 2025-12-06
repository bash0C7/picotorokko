#!/usr/bin/env ruby

require "fileutils"
require "open3"
require "pathname"

# M5Unified repository manager
class M5UnifiedRepositoryManager
  def initialize(path)
    @path = path
  end

  attr_reader :path

  # Clone M5Unified repository from remote URL
  def clone(url:, branch: "master")
    # Remove existing directory if present
    FileUtils.rm_rf(@path)

    # Create parent directory
    FileUtils.mkdir_p(File.dirname(@path))

    # Clone repository
    cmd = "git clone --branch #{branch} #{url} #{@path}"
    _, stderr, status = Open3.capture3(cmd)

    raise "Failed to clone repository: #{stderr}" unless status.success?
  end

  # Update existing repository with git pull
  def update
    raise "Repository does not exist at #{@path}" unless Dir.exist?(@path)

    cmd = "cd #{@path} && git pull"
    _, stderr, status = Open3.capture3(cmd)

    raise "Failed to update repository: #{stderr}" unless status.success?
  end

  # Get repository information
  def info
    raise "Repository does not exist at #{@path}" unless Dir.exist?(@path)

    # Get current commit hash
    cmd_commit = "cd #{@path} && git rev-parse HEAD"
    commit, = Open3.capture3(cmd_commit)

    # Get current branch
    cmd_branch = "cd #{@path} && git rev-parse --abbrev-ref HEAD"
    branch, = Open3.capture3(cmd_branch)

    {
      commit: commit.strip,
      branch: branch.strip
    }
  end
end

# C++ Header file reader
class HeaderFileReader
  def initialize(repo_path)
    @repo_path = repo_path
  end

  # List all .h files in src/ and include/ directories
  def list_headers
    headers = []
    search_dirs = ["src", "include"]

    search_dirs.each do |dir|
      dir_path = File.join(@repo_path, dir)
      next unless Dir.exist?(dir_path)

      Dir.glob(File.join(dir_path, "**", "*.h")).each do |file|
        headers << file
      end
    end

    headers.sort
  end

  # Read header file content
  def read_file(file_path)
    raise "File does not exist: #{file_path}" unless File.exist?(file_path)

    File.read(file_path)
  end
end

# C++ code parser (regex-based, simple implementation)
class CppParser
  def initialize(code)
    @code = code
  end

  # Extract class definitions from C++ code
  def extract_classes
    classes = []

    # Match class/struct declarations: class ClassName { ... };
    class_pattern = /(?:class|struct)\s+(\w+)\s*\{([^}]*)\}/m
    @code.scan(class_pattern) do |class_name, class_body|
      methods = extract_methods_from_body(class_body)
      classes << {
        name: class_name,
        methods: methods
      }
    end

    classes
  end

  private

  # Extract methods from class body
  def extract_methods_from_body(class_body)
    methods = []

    # Match method declarations: return_type method_name(params);
    # Pattern: word word(something);
    method_pattern = /(\w+)\s+(\w+)\s*\(([^)]*)\)\s*;/
    class_body.scan(method_pattern) do |return_type, method_name, params_str|
      parameters = extract_parameters(params_str)
      methods << {
        name: method_name,
        return_type: return_type,
        parameters: parameters
      }
    end

    methods
  end

  # Extract parameters from parameter string
  def extract_parameters(params_str)
    parameters = []

    # Split by comma for multiple parameters
    params_str.split(",").each do |param|
      param = param.strip
      next if param.empty?

      # Extract type and name: "int x" => type: "int", name: "x"
      parts = param.split(/\s+/)
      if parts.length >= 2
        parameters << {
          type: parts[0],
          name: parts[-1]
        }
      elsif parts.length == 1
        # Single word parameter (edge case)
        parameters << {
          type: parts[0],
          name: parts[0]
        }
      end
    end

    parameters
  end
end

# C++ type to mrubyc type mapper
class TypeMapper
  TYPE_MAPPING = {
    # Integer types
    "int" => "MRBC_TT_INTEGER",
    "int8_t" => "MRBC_TT_INTEGER",
    "int16_t" => "MRBC_TT_INTEGER",
    "int32_t" => "MRBC_TT_INTEGER",
    "int64_t" => "MRBC_TT_INTEGER",
    "uint8_t" => "MRBC_TT_INTEGER",
    "uint16_t" => "MRBC_TT_INTEGER",
    "uint32_t" => "MRBC_TT_INTEGER",
    "uint64_t" => "MRBC_TT_INTEGER",
    "unsigned int" => "MRBC_TT_INTEGER",
    "long" => "MRBC_TT_INTEGER",
    "unsigned long" => "MRBC_TT_INTEGER",
    "size_t" => "MRBC_TT_INTEGER",

    # Float types
    "float" => "MRBC_TT_FLOAT",
    "double" => "MRBC_TT_FLOAT",

    # String types
    "char*" => "MRBC_TT_STRING",

    # Boolean type
    "bool" => "MRBC_TT_TRUE"
  }.freeze

  def self.map_type(cpp_type)
    normalized = normalize_type(cpp_type)
    return "nil" if normalized == "void"

    return "MRBC_TT_OBJECT" if pointer_type?(normalized) && !normalized.include?("char")

    TYPE_MAPPING[normalized] || "MRBC_TT_OBJECT"
  end

  def self.normalize_type(cpp_type)
    cpp_type.strip.gsub(/^const\s+/, "").gsub(/&$/, "")
  end

  def self.pointer_type?(cpp_type)
    cpp_type.end_with?("*")
  end
end

# mrbgem directory structure and template file generator
class MrbgemGenerator
  def initialize(output_path)
    @output_path = output_path
  end

  attr_reader :output_path

  # Generate complete mrbgem structure and template files
  # @param cpp_data [Array<Hash>] Parsed C++ class data
  # @return [Boolean] true on success
  def generate(cpp_data)
    create_structure
    render_mrbgem_rake
    render_c_bindings(cpp_data)
    render_ruby_lib(cpp_data)
    render_readme(cpp_data)
    render_cpp_wrapper(cpp_data)
    render_cmake
    true
  end

  private

  # Create base directory structure
  def create_structure
    FileUtils.mkdir_p(@output_path)
    FileUtils.mkdir_p(File.join(@output_path, "mrblib"))
    FileUtils.mkdir_p(File.join(@output_path, "src"))
    FileUtils.mkdir_p(File.join(@output_path, "ports", "esp32"))
  end

  # Generate mrbgem.rake with gem specification
  def render_mrbgem_rake
    content = "MRuby::Gem::Specification.new('picoruby-m5unified') do |spec|\n  " \
              "spec.license = 'MIT'\n  " \
              "spec.author  = 'PicoTorokko'\n  " \
              "spec.summary = 'M5Unified bindings for PicoRuby'\n" \
              "end\n"
    File.write(File.join(@output_path, "mrbgem.rake"), content)
  end

  # Generate src/m5unified.c with C binding skeleton
  def render_c_bindings(cpp_data)
    content = "/*\n"
    content += " * M5Unified C Bindings for PicoRuby\n"
    content += " * Auto-generated by PicoTorokko\n"
    content += " */\n\n"
    content += "#include <mrubyc.h>\n\n"
    content += generate_forward_declarations(cpp_data)
    content += generate_function_wrappers(cpp_data)
    content += generate_gem_init(cpp_data)
    File.write(File.join(@output_path, "src", "m5unified.c"), content)
  end

  # Generate forward declarations for classes and extern function declarations
  def generate_forward_declarations(cpp_data)
    content = "/* Forward declarations */\n"
    cpp_data.each do |klass|
      content += "static mrbc_class *c_#{klass[:name]};\n"
    end

    content += "\n/* Extern declarations for wrapper functions */\n"
    cpp_data.each do |klass|
      klass[:methods].each do |method|
        # Map C++ return type directly to C type (not mruby type)
        return_type = map_return_type_to_c(method[:return_type])
        func_name = "m5unified_#{method[:name]}"
        param_list = if method[:parameters].empty?
                       "void"
                     else
                       method[:parameters].map do |p|
                         "#{p[:type]} #{p[:name]}"
                       end.join(", ")
                     end
        content += "extern #{return_type} #{func_name}(#{param_list});\n"
      end
    end

    "#{content}\n"
  end

  # Map C++ return type to C return type for extern declarations
  def map_return_type_to_c(cpp_type)
    normalized = cpp_type.strip.gsub(/^const\s+/, "").gsub(/&$/, "")
    return "void" if normalized == "void"
    return "int" if normalized == "bool"

    normalized
  end

  # Generate C function wrappers for all methods
  def generate_function_wrappers(cpp_data)
    content = "/* Method wrappers */\n"
    cpp_data.each do |klass|
      klass[:methods].each do |method|
        content += generate_method_wrapper(klass[:name], method)
      end
    end
    "#{content}\n"
  end

  # Generate a single method wrapper function
  def generate_method_wrapper(_class_name, method)
    func_name = "mrbc_m5unified_#{method[:name]}"
    content = "static void #{func_name}(mrbc_vm *vm, mrbc_value *v, int argc) {\n"

    # Generate parameter extraction code
    method[:parameters].each_with_index do |param, index|
      conversion = generate_parameter_conversion(param, index + 1)
      content += "  #{conversion}\n"
    end

    # Generate return value marshalling
    content += "  #{generate_return_marshalling(method[:return_type])}\n"
    content += "}\n\n"

    content
  end

  # Generate parameter conversion code based on type
  def generate_parameter_conversion(parameter, arg_index)
    type = parameter[:type]
    mruby_type = TypeMapper.map_type(type)
    name = parameter[:name]

    case mruby_type
    when "MRBC_TT_INTEGER"
      "int #{name} = v[#{arg_index}].value.i;"
    when "MRBC_TT_FLOAT"
      "float #{name} = (float)v[#{arg_index}].value.f;"
    when "MRBC_TT_STRING"
      "const char *#{name} = mrbc_string_cstr(&v[#{arg_index}]);"
    when "MRBC_TT_OBJECT"
      "void *#{name} = mrbc_obj_get_ptr(&v[#{arg_index}]);"
    else
      "/* #{type} #{name} - unsupported type conversion */"
    end
  end

  # Generate return value marshalling code based on return type
  def generate_return_marshalling(return_type)
    mruby_type = TypeMapper.map_type(return_type)

    case mruby_type
    when "MRBC_TT_INTEGER"
      "SET_RETURN(mrbc_integer_value(0)); /* result */"
    when "MRBC_TT_FLOAT"
      "SET_RETURN(mrbc_float_value(0.0)); /* result */"
    when "MRBC_TT_STRING"
      "SET_RETURN(mrbc_string_value(vm, \"\", 0)); /* result */"
    when "nil"
      "/* void return */"
    else
      "/* #{return_type} return */"
    end
  end

  # Generate mrbc_m5unified_gem_init function
  def generate_gem_init(cpp_data)
    content = "void mrbc_m5unified_gem_init(mrbc_vm *vm) {\n"
    cpp_data.each do |klass|
      content += "  c_#{klass[:name]} = mrbc_define_class(vm, \"#{klass[:name]}\", 0, 0, 0);\n"
      klass[:methods].each do |method|
        method_func = "mrbc_m5unified_#{method[:name]}"
        content += "  mrbc_define_method(vm, c_#{klass[:name]}, \"#{method[:name]}\", #{method_func});\n"
      end
    end
    "#{content}}\n"
  end

  # Generate mrblib/m5unified.rb with class documentation
  def render_ruby_lib(cpp_data)
    content = "# M5Unified Ruby bindings for PicoRuby\n"
    content += "# Auto-generated by PicoTorokko\n\n"
    content += "# Classes:\n"
    cpp_data.each do |klass|
      content += "# - #{klass[:name]}\n"
    end
    content += "\n# This file serves as documentation for the C bindings\n"
    content += "# implemented in src/m5unified.c\n"
    File.write(File.join(@output_path, "mrblib", "m5unified.rb"), content)
  end

  # Generate README.md with gem documentation
  def render_readme(cpp_data)
    content = "# picoruby-m5unified\n\n"
    content += "M5Unified bindings for PicoRuby.\n\n"
    content += "## Classes\n\n"
    cpp_data.each do |klass|
      content += "- #{klass[:name]}\n"
    end
    content += "\n## Building\n\n"
    content += "This gem is built as part of the PicoRuby project.\n\n"
    content += "## License\n\nMIT\n"
    File.write(File.join(@output_path, "README.md"), content)
  end

  # Generate C++ wrapper file for extern "C" layer
  def render_cpp_wrapper(cpp_data)
    generator = CppWrapperGenerator.new(cpp_data)
    content = generator.generate
    wrapper_path = File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp")
    File.write(wrapper_path, content)
  end

  # Generate CMakeLists.txt for ESP-IDF component registration
  def render_cmake
    generator = CMakeGenerator.new
    content = generator.generate
    File.write(File.join(@output_path, "CMakeLists.txt"), content)
  end
end

# C++ wrapper function generator for extern "C" layer
class CppWrapperGenerator
  def initialize(cpp_data)
    @cpp_data = cpp_data
  end

  # Generate extern "C" wrapper file content
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

  # Generate a single wrapper function
  def generate_wrapper_function(klass_name, method)
    func_name = flatten_method_name(klass_name, method[:name])
    return_type = map_cpp_return_type(method[:return_type])
    params = generate_cpp_params(method[:parameters])

    content = "#{return_type} #{func_name}(#{params}) {\n"

    # bool → int 変換
    api_call = generate_api_call(klass_name, method[:name], method[:parameters])
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

  # Flatten namespace hierarchy: M5.begin → m5unified_begin, M5.BtnA.wasPressed → m5unified_btna_wasPressed
  def flatten_method_name(klass_name, method_name)
    if klass_name == "M5"
      "m5unified_#{method_name}"
    else
      "m5unified_#{klass_name.downcase}_#{method_name}"
    end
  end

  # Map C++ return type to wrapper return type
  def map_cpp_return_type(cpp_type)
    return "void" if cpp_type == "void"
    return "int" if cpp_type == "bool"

    cpp_type
  end

  # Generate parameter list for C++ function
  def generate_cpp_params(parameters)
    return "void" if parameters.empty?

    parameters.map { |p| "#{p[:type]} #{p[:name]}" }.join(", ")
  end

  # Generate M5 API call
  def generate_api_call(klass_name, method_name, parameters)
    param_names = parameters.map { |p| p[:name] }.join(", ")
    if klass_name == "M5"
      "M5.#{method_name}(#{param_names})"
    else
      "M5.#{klass_name}.#{method_name}(#{param_names})"
    end
  end
end

# ESP-IDF CMake generator for component registration
class CMakeGenerator
  # Generate CMakeLists.txt for ESP-IDF component
  def generate
    content = "idf_component_register(\n"
    content += "  SRCS\n"
    content += "    \"ports/esp32/m5unified_wrapper.cpp\"\n"
    content += "    \"src/m5unified.c\"\n"
    content += "  INCLUDE_DIRS\n"
    content += "    \".\"\n"
    content += "  REQUIRES\n"
    content += "    m5unified\n"
    content += ")\n\n"
    content += "target_link_libraries(${COMPONENT_LIB} PUBLIC\n"
    content += "  m5unified\n"
    content += ")\n"
    content
  end
end
