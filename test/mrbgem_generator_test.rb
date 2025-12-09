# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/m5libgen/lib/m5libgen/mrbgem_generator"
require_relative "../lib/m5libgen/lib/m5libgen/cpp_wrapper_generator"
require_relative "../lib/m5libgen/lib/m5libgen/cmake_generator"
require "tmpdir"
require "fileutils"

# Test M5LibGen::MrbgemGenerator
class MrbgemGeneratorTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir("mrbgem_test")
    @output_path = File.join(@tmpdir, "mrbgem-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_extern_declarations_with_correct_signatures
    cpp_data = [
      {
        name: "LED_Class",
        methods: [
          {
            name: "begin",
            return_type: "void",
            parameters: []
          },
          {
            name: "setBrightness",
            return_type: "void",
            parameters: [{ type: "uint8_t", name: "brightness" }]
          },
          {
            name: "isReady",
            return_type: "bool",
            parameters: []
          }
        ]
      }
    ]

    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    generator.generate(cpp_data)

    c_file = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Check extern declarations have correct signatures with parameter count suffix
    # void function with no params
    assert_match(/extern void m5unified_led_class_begin_0\(void\);/, c_file)
    # void function with one param
    assert_match(/extern void m5unified_led_class_setbrightness_1\(uint8_t brightness\);/, c_file)
    # int function (bool → int) with no params
    assert_match(/extern int m5unified_led_class_isready_0\(void\);/, c_file)

    # Should NOT have generic "extern void func(void)" for all methods
    refute_match(/extern void m5unified_led_class_setbrightness_1\(void\);/,  c_file,
                 "Should not have void(void) for method with parameters")
  end

  def test_extern_declarations_with_int_params
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

    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    generator.generate(cpp_data)

    c_file = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Should have correct parameter types with count suffix
    assert_match(/extern int m5unified_i2c_class_begin_2\(int sda, int scl\);/, c_file)
  end

  def test_wrapper_function_calls_extern_with_no_params
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

    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    generator.generate(cpp_data)

    c_file = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Should call extern function with param count suffix
    assert_match(/m5unified_led_class_begin_0\(\);/, c_file)
    # Should not have TODO stub
    refute_match(/\/\* TODO: Call wrapper function \*\//, c_file)
  end

  def test_wrapper_function_with_int_parameters
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

    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    generator.generate(cpp_data)

    c_file = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Should extract parameters from mruby stack
    assert_match(/GET_INT_ARG\(1\)/, c_file)
    assert_match(/GET_INT_ARG\(2\)/, c_file)
    # Should call extern function with parameters (with count suffix)
    assert_match(/m5unified_i2c_class_begin_2\(.*sda.*scl\)/, c_file)
  end

  def test_wrapper_function_with_bool_return
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

    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    generator.generate(cpp_data)

    c_file = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Should convert int result (0/1) back to bool (with count suffix)
    assert_match(/int result = m5unified_button_class_waspressed_0\(\);/, c_file)
    assert_match(/SET_BOOL_RETURN\(result\)/, c_file)
  end

  def test_wrapper_function_with_void_return
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

    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    generator.generate(cpp_data)

    c_file = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Should call function without return (with count suffix)
    assert_match(/m5unified_display_class_clear_0\(\);/, c_file)
    # Should return nil
    assert_match(/SET_RETURN\(mrbc_nil_value\(\)\);/, c_file)
  end

  def test_method_overloading_unique_extern_names
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
          }
        ]
      }
    ]

    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    generator.generate(cpp_data)

    c_file = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Should have unique extern declarations
    assert_match(/extern int m5unified_i2c_class_begin_0\(void\);/, c_file)
    assert_match(/extern int m5unified_i2c_class_begin_2\(int sda, int scl\);/, c_file)

    # Should have unique wrapper functions
    assert_match(/static void mrbc_m5_begin_0\(mrbc_vm/, c_file)
    assert_match(/static void mrbc_m5_begin_2\(mrbc_vm/, c_file)

    # Should call correct extern functions
    assert_match(/m5unified_i2c_class_begin_0\(\);/, c_file)
    assert_match(/m5unified_i2c_class_begin_2\(sda, scl\);/, c_file)
  end
end
