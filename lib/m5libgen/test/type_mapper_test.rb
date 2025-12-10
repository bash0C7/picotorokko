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
    assert_equal false, M5LibGen::TypeMapper.unsupported_type?("Foo*")
    assert_equal false, M5LibGen::TypeMapper.unsupported_type?("Foo&")
  end
end
