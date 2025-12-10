# frozen_string_literal: true

module M5LibGen
  # Maps C++ types to mrubyc types
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

    # Detect if a C++ type is unsupported for mrubyc binding
    def self.unsupported_type?(cpp_type)
      # Function pointers: void (*callback)(int)
      return true if cpp_type.include?("(*")

      # Rvalue references: Type&&
      return true if cpp_type.include?("&&")

      # Template types: std::function<>, CustomTemplate<>
      # Note: We could whitelist specific safe templates in the future
      return true if cpp_type.include?("<") && cpp_type.include?(">")

      false
    end
  end
end
