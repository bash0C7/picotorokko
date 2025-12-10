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
      # Invalid type names: cfg.atom_display (struct member access as type)
      return true if cpp_type.include?(".") || cpp_type.include?("->")

      # Function pointers: void (*callback)(int)
      return true if cpp_type.include?("(*")

      # Rvalue references: Type&&
      return true if cpp_type.include?("&&")

      # Template types: std::function<>, CustomTemplate<>
      # Note: We could whitelist specific safe templates in the future
      return true if cpp_type.include?("<") && cpp_type.include?(">")

      # Object references: M5GFX&, Button_Class&, Display_Device&
      # These are C++ class instances that cannot be passed to/from mrubyc
      return true if is_object_reference?(cpp_type)

      # Struct references: rtc_time_t&, config_t&, touch_detail_t&
      # mrubyc doesn't support struct marshalling
      return true if is_struct_reference?(cpp_type)

      # Pointer arrays (except char*): const uint8_t*, int16_t*
      # mrubyc doesn't have built-in array marshalling
      return true if is_pointer_array?(cpp_type)

      false
    end

    # Check if type is an object reference (C++ class reference)
    def self.is_object_reference?(cpp_type)
      return false unless cpp_type.include?("&")

      normalized = cpp_type.strip.gsub(/^const\s+/, "").gsub(/&$/, "")

      # Common M5Unified object types
      object_patterns = [
        /^M5[A-Z]/,           # M5GFX, M5Canvas, M5Display, etc.
        /Button_Class$/,       # Button_Class
        /Display_Device$/,     # Display_Device
        /_Class$/,             # Any _Class suffix
        /^IOExpander/          # IOExpander_Base, etc.
      ]

      object_patterns.any? { |pattern| normalized.match?(pattern) }
    end

    # Check if type is a struct reference
    def self.is_struct_reference?(cpp_type)
      return false unless cpp_type.include?("&")

      normalized = cpp_type.strip.gsub(/^const\s+/, "").gsub(/&$/, "")

      # Common struct patterns in M5Unified
      struct_patterns = [
        /_t$/,                 # rtc_time_t, config_t, touch_detail_t
        /^RGBColor$/,          # RGBColor struct
        /^point\d+d/,          # point3d_i16_t, etc.
        /^wav_info/            # wav_info_t
      ]

      struct_patterns.any? { |pattern| normalized.match?(pattern) }
    end

    # Check if type is a pointer to array (not string)
    def self.is_pointer_array?(cpp_type)
      return false unless cpp_type.include?("*")
      return false if cpp_type.include?("char") # char* is OK (string)
      return false if cpp_type.include?("void") # void* might be OK

      # Pointer to numeric types: const uint8_t*, int16_t*, float*, etc.
      pointer_patterns = [
        /u?int\d+_t\s*\*/,     # uint8_t*, int16_t*, etc.
        /float\s*\*/,          # float*
        /double\s*\*/          # double*
      ]

      pointer_patterns.any? { |pattern| cpp_type.match?(pattern) }
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
