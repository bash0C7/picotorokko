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
