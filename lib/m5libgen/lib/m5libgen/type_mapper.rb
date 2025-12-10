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

    # Get mrubyc GET_*_ARG macro for extracting parameter from stack
    def self.get_arg_macro(cpp_type)
      normalized = normalize_type(cpp_type)

      case normalized
      when "bool"
        "GET_INT_ARG"  # bool is represented as int in C
      when "int", "int8_t", "int16_t", "int32_t", "int64_t",
           "uint8_t", "uint16_t", "uint32_t", "uint64_t",
           "unsigned int", "long", "unsigned long", "size_t"
        "GET_INT_ARG"
      when "float", "double"
        "GET_FLOAT_ARG"
      when "char*", "const char*"
        "GET_STRING_ARG"
      else
        # Pointers and objects
        if pointer_type?(normalized) || cpp_type.include?("&")
          "GET_INT_ARG"  # Treat as opaque pointer (integer)
        else
          "GET_INT_ARG"  # Default fallback
        end
      end
    end

    # Get mrubyc SET_*_RETURN macro for setting return value
    def self.set_return_macro(cpp_type)
      normalized = normalize_type(cpp_type)

      case normalized
      when "void"
        "SET_NIL_RETURN"
      when "bool"
        "SET_BOOL_RETURN"  # Special handling for bool
      when "int", "int8_t", "int16_t", "int32_t", "int64_t",
           "uint8_t", "uint16_t", "uint32_t", "uint64_t",
           "unsigned int", "long", "unsigned long", "size_t"
        "SET_INT_RETURN"
      when "float", "double"
        "SET_FLOAT_RETURN"
      when "char*", "const char*"
        "SET_STRING_RETURN"
      else
        # Pointers and objects
        if pointer_type?(normalized) || cpp_type.include?("&")
          "SET_INT_RETURN"  # Treat as opaque pointer (integer)
        else
          "SET_INT_RETURN"  # Default fallback
        end
      end
    end

    # Get C type for mrubyc variable declaration
    def self.get_c_type_for_param(cpp_type)
      normalized = normalize_type(cpp_type)

      case normalized
      when "bool"
        "int"  # bool is represented as int in C
      when "float"
        "float"
      when "double"
        "double"
      when "char*", "const char*"
        "const char*"
      else
        cpp_type  # Use original type
      end
    end
  end
end
