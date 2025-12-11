# frozen_string_literal: true

require_relative "test_helper"

# Test M5LibGen::TypeMapper
class TypeMapperTest < Test::Unit::TestCase
  def test_map_integer_types
    assert_equal "MRBC_TT_INTEGER", M5LibGen::TypeMapper.map_type("int")
    assert_equal "MRBC_TT_INTEGER", M5LibGen::TypeMapper.map_type("int8_t")
    assert_equal "MRBC_TT_INTEGER", M5LibGen::TypeMapper.map_type("uint32_t")
    assert_equal "MRBC_TT_INTEGER", M5LibGen::TypeMapper.map_type("size_t")
  end

  def test_map_float_types
    assert_equal "MRBC_TT_FLOAT", M5LibGen::TypeMapper.map_type("float")
    assert_equal "MRBC_TT_FLOAT", M5LibGen::TypeMapper.map_type("double")
  end

  def test_map_string_types
    assert_equal "MRBC_TT_STRING", M5LibGen::TypeMapper.map_type("char*")
    assert_equal "MRBC_TT_STRING", M5LibGen::TypeMapper.map_type("const char*")
  end

  def test_map_bool_type
    assert_equal "MRBC_TT_TRUE", M5LibGen::TypeMapper.map_type("bool")
  end

  def test_map_void_type
    assert_equal "nil", M5LibGen::TypeMapper.map_type("void")
  end

  def test_map_pointer_types
    assert_equal "MRBC_TT_OBJECT", M5LibGen::TypeMapper.map_type("Foo*")
    assert_equal "MRBC_TT_OBJECT", M5LibGen::TypeMapper.map_type("Bar*")
  end

  def test_normalize_const_qualifier
    assert_equal "MRBC_TT_INTEGER", M5LibGen::TypeMapper.map_type("const int")
    assert_equal "MRBC_TT_STRING", M5LibGen::TypeMapper.map_type("const char*")
  end

  def test_normalize_reference_types
    assert_equal "MRBC_TT_INTEGER", M5LibGen::TypeMapper.map_type("int&")
    assert_equal "MRBC_TT_OBJECT", M5LibGen::TypeMapper.map_type("Foo&")
  end

  # Issue 2-3: Complex type detection
  def test_detect_function_pointer_type
    assert_equal true, M5LibGen::TypeMapper.unsupported_type?("void (*callback)(int)"),
                 "Function pointer should be detected as unsupported"
    assert_equal true, M5LibGen::TypeMapper.unsupported_type?("int (*func)(float, double)"),
                 "Function pointer should be detected as unsupported"
  end

  def test_detect_template_type
    # Generic templates are unsupported
    assert_equal true, M5LibGen::TypeMapper.unsupported_type?("std::function<void()>"),
                 "std::function template should be detected as unsupported"
    assert_equal true, M5LibGen::TypeMapper.unsupported_type?("CustomTemplate<int>"),
                 "Custom template should be detected as unsupported"
  end

  def test_detect_rvalue_reference
    assert_equal true, M5LibGen::TypeMapper.unsupported_type?("Foo&&"),
                 "Rvalue reference should be detected as unsupported"
    assert_equal true, M5LibGen::TypeMapper.unsupported_type?("std::string&&"),
                 "Rvalue reference should be detected as unsupported"
  end

  def test_supported_types_are_not_flagged
    # Basic types should be supported
    assert_equal false, M5LibGen::TypeMapper.unsupported_type?("int")
    assert_equal false, M5LibGen::TypeMapper.unsupported_type?("float")
    assert_equal false, M5LibGen::TypeMapper.unsupported_type?("bool")
    assert_equal false, M5LibGen::TypeMapper.unsupported_type?("const char*")
    assert_equal false, M5LibGen::TypeMapper.unsupported_type?("void")
  end

  # New tests for comprehensive type detection
  def test_unsupported_type_detects_invalid_type_names
    # cfg.atom_display - struct member access as type name
    assert_true M5LibGen::TypeMapper.unsupported_type?("cfg.atom_display")
    assert_true M5LibGen::TypeMapper.unsupported_type?("config->member")
  end

  def test_is_object_reference_detects_class_instances
    # M5Unified object types
    assert_true M5LibGen::TypeMapper.is_object_reference?("M5GFX&")
    assert_true M5LibGen::TypeMapper.is_object_reference?("const M5GFX&")
    assert_true M5LibGen::TypeMapper.is_object_reference?("Button_Class&")
    assert_true M5LibGen::TypeMapper.is_object_reference?("Display_Device&")
    assert_true M5LibGen::TypeMapper.is_object_reference?("IOExpander_Base&")

    # Not object references
    assert_false M5LibGen::TypeMapper.is_object_reference?("int")
    assert_false M5LibGen::TypeMapper.is_object_reference?("config_t&") # struct, not object
    assert_false M5LibGen::TypeMapper.is_object_reference?("M5GFX*")    # pointer, not reference
  end

  def test_is_struct_reference_detects_struct_types
    # Common M5Unified struct types
    assert_true M5LibGen::TypeMapper.is_struct_reference?("config_t&")
    assert_true M5LibGen::TypeMapper.is_struct_reference?("const rtc_time_t&")
    assert_true M5LibGen::TypeMapper.is_struct_reference?("touch_detail_t&")
    assert_true M5LibGen::TypeMapper.is_struct_reference?("RGBColor&")
    assert_true M5LibGen::TypeMapper.is_struct_reference?("point3d_i16_t&")
    assert_true M5LibGen::TypeMapper.is_struct_reference?("wav_info_t&")

    # Not struct references
    assert_false M5LibGen::TypeMapper.is_struct_reference?("int")
    assert_false M5LibGen::TypeMapper.is_struct_reference?("M5GFX&")  # object, not struct
    assert_false M5LibGen::TypeMapper.is_struct_reference?("config_t*") # pointer, not reference
  end

  def test_is_pointer_array_detects_numeric_pointers
    # Numeric array pointers
    assert_true M5LibGen::TypeMapper.is_pointer_array?("const uint8_t*")
    assert_true M5LibGen::TypeMapper.is_pointer_array?("int16_t*")
    assert_true M5LibGen::TypeMapper.is_pointer_array?("float*")
    assert_true M5LibGen::TypeMapper.is_pointer_array?("double*")

    # Allowed pointer types
    assert_false M5LibGen::TypeMapper.is_pointer_array?("const char*")  # string is OK
    assert_false M5LibGen::TypeMapper.is_pointer_array?("char*")        # string is OK
    assert_false M5LibGen::TypeMapper.is_pointer_array?("void*")        # might be OK
    assert_false M5LibGen::TypeMapper.is_pointer_array?("int")          # not a pointer
  end

  def test_unsupported_type_comprehensive_check
    # All P0/P1 problematic types should be detected
    assert_true M5LibGen::TypeMapper.unsupported_type?("cfg.atom_display")      # P0: invalid name
    assert_true M5LibGen::TypeMapper.unsupported_type?("M5GFX&")                # P1: object ref
    assert_true M5LibGen::TypeMapper.unsupported_type?("Button_Class&")         # P1: object ref
    assert_true M5LibGen::TypeMapper.unsupported_type?("const config_t&")       # P1: struct ref
    assert_true M5LibGen::TypeMapper.unsupported_type?("rtc_time_t&")           # P1: struct ref
    assert_true M5LibGen::TypeMapper.unsupported_type?("const uint8_t*")        # P1: pointer array
    assert_true M5LibGen::TypeMapper.unsupported_type?("void (*)(int)")         # Function pointer
    assert_true M5LibGen::TypeMapper.unsupported_type?("Type&&")                # Rvalue ref
    assert_true M5LibGen::TypeMapper.unsupported_type?("std::function<void()>") # Template

    # Supported types should pass
    assert_false M5LibGen::TypeMapper.unsupported_type?("int")
    assert_false M5LibGen::TypeMapper.unsupported_type?("float")
    assert_false M5LibGen::TypeMapper.unsupported_type?("bool")
    assert_false M5LibGen::TypeMapper.unsupported_type?("const char*")
    assert_false M5LibGen::TypeMapper.unsupported_type?("void")
  end
end
