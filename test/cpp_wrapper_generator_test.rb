# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/m5libgen/lib/m5libgen/cpp_wrapper_generator"

# Test M5LibGen::CppWrapperGenerator
class CppWrapperGeneratorTest < Test::Unit::TestCase
  def test_generate_method_with_no_parameters
    cpp_data = [
      {
        name: "LED_Class",
        methods: [
          {
            name: "begin",
            return_type: "void",
            parameters: []
          }
        ]
      }
    ]

    generator = M5LibGen::CppWrapperGenerator.new(cpp_data)
    result = generator.generate

    # Should generate: void m5unified_led_class_begin_0(void)
    # NOT: void m5unified_led_class_begin(void void)
    assert_match(/void m5unified_led_class_begin_0\(void\)/, result)
    refute_match(/void void/, result, "Should not have duplicate 'void void'")
  end

  def test_generate_method_with_parameters
    cpp_data = [
      {
        name: "I2C_Class",
        methods: [
          {
            name: "begin",
            return_type: "bool",
            parameters: [
              { type: "int", name: "sda" },
              { type: "int", name: "scl" }
            ]
          }
        ]
      }
    ]

    generator = M5LibGen::CppWrapperGenerator.new(cpp_data)
    result = generator.generate

    # Should generate: int m5unified_i2c_class_begin_2(int sda, int scl)
    assert_match(/int m5unified_i2c_class_begin_2\(int sda, int scl\)/, result)
    assert_match(/M5\.I2C_Class\.begin\(sda, scl\)/, result)
  end

  def test_generate_bool_return_converts_to_int
    cpp_data = [
      {
        name: "Button_Class",
        methods: [
          {
            name: "wasPressed",
            return_type: "bool",
            parameters: []
          }
        ]
      }
    ]

    generator = M5LibGen::CppWrapperGenerator.new(cpp_data)
    result = generator.generate

    # Bool should be converted to int in C wrapper
    assert_match(/int m5unified_button_class_waspressed_0\(void\)/, result)
    assert_match(/return.*\? 1 : 0/, result)
  end

  def test_generate_void_return_no_return_statement
    cpp_data = [
      {
        name: "Display_Class",
        methods: [
          {
            name: "clear",
            return_type: "void",
            parameters: []
          }
        ]
      }
    ]

    generator = M5LibGen::CppWrapperGenerator.new(cpp_data)
    result = generator.generate

    # Void return should not have 'return' statement
    assert_match(/void m5unified_display_class_clear_0\(void\)/, result)
    assert_match(/M5\.Display_Class\.clear\(\);/, result)
    # The line should NOT start with 'return'
    refute_match(/^\s*return.*clear/, result.lines.join, "Void function should not have return statement")
  end

  def test_generate_const_method
    cpp_data = [
      {
        name: "Config",
        methods: [
          {
            name: "getValue",
            return_type: "int",
            parameters: [],
            is_const: true
          }
        ]
      }
    ]

    generator = M5LibGen::CppWrapperGenerator.new(cpp_data)
    result = generator.generate

    # Const methods should be callable (no special syntax needed in extern C)
    assert_match(/int m5unified_config_getvalue_0\(void\)/, result)
    assert_match(/return M5\.Config\.getValue\(\)/, result)
  end

  def test_method_overloading_unique_function_names
    cpp_data = [
      {
        name: "I2C_Class",
        methods: [
          {
            name: "begin",
            return_type: "bool",
            parameters: []
          },
          {
            name: "begin",
            return_type: "bool",
            parameters: [
              { type: "int", name: "sda" },
              { type: "int", name: "scl" }
            ]
          },
          {
            name: "begin",
            return_type: "bool",
            parameters: [
              { type: "int", name: "sda" },
              { type: "int", name: "scl" },
              { type: "uint32_t", name: "freq" }
            ]
          }
        ]
      }
    ]

    generator = M5LibGen::CppWrapperGenerator.new(cpp_data)
    result = generator.generate

    # Should generate unique function names based on parameter count
    assert_match(/int m5unified_i2c_class_begin_0\(void\)/, result)
    assert_match(/int m5unified_i2c_class_begin_2\(int sda, int scl\)/, result)
    assert_match(/int m5unified_i2c_class_begin_3\(int sda, int scl, uint32_t freq\)/, result)

    # Should NOT have duplicate function names
    refute_match(/int m5unified_i2c_class_begin\(void\).*int m5unified_i2c_class_begin\(int/m, result,
                 "Should not have duplicate function names")
  end
end
