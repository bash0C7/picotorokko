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

    # Check extern declarations have correct signatures
    # void function with no params
    assert_match(/extern void m5unified_led_class_begin\(void\);/, c_file)
    # void function with one param
    assert_match(/extern void m5unified_led_class_setbrightness\(uint8_t brightness\);/, c_file)
    # int function (bool → int) with no params
    assert_match(/extern int m5unified_led_class_isready\(void\);/, c_file)

    # Should NOT have generic "extern void func(void)" for all methods
    refute_match(/extern void m5unified_led_class_setbrightness\(void\);/,  c_file,
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

    # Should have correct parameter types
    assert_match(/extern int m5unified_i2c_class_begin\(int sda, int scl\);/, c_file)
  end
end
