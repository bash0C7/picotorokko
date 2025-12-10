# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

# Integration test to verify C bindings and C++ wrapper consistency
class IntegrationTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir("m5libgen_integration_test")
    @output_path = File.join(@tmpdir, "mrbgem-integration")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # Issue #1: C bindings must use same function names as C++ wrapper
  def test_function_name_consistency_between_c_and_cpp
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    test_data = [
      {
        name: "Display",
        methods: [
          {
            name: "drawPixel",
            return_type: "void",
            parameters: [
              { type: "int", name: "x" },
              { type: "int", name: "y" }
            ],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(test_data)

    # Read generated C bindings
    c_bindings_path = File.join(@output_path, "src", "m5unified.c")
    c_content = File.read(c_bindings_path)

    # Read generated C++ wrapper
    cpp_wrapper_path = File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp")
    cpp_content = File.read(cpp_wrapper_path)

    # C++ wrapper defines: void m5unified_display_drawpixel_int_int(int x, int y)
    cpp_function_name = "m5unified_display_drawpixel_int_int"
    assert_includes cpp_content, cpp_function_name,
                    "C++ wrapper should define #{cpp_function_name}"

    # C bindings must declare: extern void m5unified_display_drawpixel_int_int(int x, int y)
    assert_includes c_content, "extern void #{cpp_function_name}",
                    "C bindings should declare extern #{cpp_function_name}"

    # C bindings must call: m5unified_display_drawpixel_int_int(x, y)
    assert_includes c_content, "#{cpp_function_name}(",
                    "C bindings should call #{cpp_function_name}"
  end

  # Issue #1: Overloaded methods must have unique names
  def test_overloaded_methods_have_unique_names
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    test_data = [
      {
        name: "Display",
        methods: [
          {
            name: "draw",
            return_type: "void",
            parameters: [{ type: "int", name: "x" }],
            is_static: false,
            is_const: false,
            is_virtual: false
          },
          {
            name: "draw",
            return_type: "void",
            parameters: [{ type: "float", name: "f" }],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(test_data)

    cpp_wrapper_path = File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp")
    cpp_content = File.read(cpp_wrapper_path)

    # Extract all function definitions
    function_names = cpp_content.scan(/^(\w+)\s+(m5unified_\w+)\(/).map { |match| match[1] }

    # All function names should be unique
    assert_equal function_names.uniq.size, function_names.size,
                 "All function names should be unique. Found duplicates: #{function_names.group_by(&:itself).select { |_, v| v.size > 1 }.keys}"

    # Should have two distinct names (type-based naming)
    assert_equal 2, function_names.size, "Should have 2 wrapper functions"
    assert_includes function_names, "m5unified_display_draw_int"
    assert_includes function_names, "m5unified_display_draw_float"
  end

  # Issue #2: Parameter names must be sanitized consistently
  def test_parameter_sanitization_consistency
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    test_data = [
      {
        name: "Config",
        methods: [
          {
            name: "setup",
            return_type: "void",
            parameters: [
              { type: "int", name: "cfg.atom" }  # Invalid parameter name (contains dot)
            ],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(test_data)

    # Read generated files
    c_content = File.read(File.join(@output_path, "src", "m5unified.c"))
    cpp_content = File.read(File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp"))

    # Neither file should contain invalid parameter name "cfg.atom"
    refute_includes c_content, "cfg.atom",
                    "C bindings should not contain invalid parameter name 'cfg.atom'"
    refute_includes cpp_content, "cfg.atom",
                    "C++ wrapper should not contain invalid parameter name 'cfg.atom'"

    # Should use sanitized name param_0 (parameter name was invalid, but type is valid)
    assert_includes cpp_content, "param_0",
                    "C++ wrapper should use sanitized parameter name 'param_0'"
  end

  # Integration: Verify complete flow
  def test_complete_integration_flow
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    test_data = [
      {
        name: "Button",
        methods: [
          {
            name: "wasPressed",
            return_type: "bool",
            parameters: [],
            is_static: false,
            is_const: true,
            is_virtual: false
          }
        ]
      }
    ]

    result = generator.generate(test_data)

    # Should return statistics
    assert_kind_of Hash, result
    assert_equal 1, result[:generated_count]

    # All files should exist
    assert File.exist?(File.join(@output_path, "src", "m5unified.c"))
    assert File.exist?(File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp"))

    # Read contents
    c_content = File.read(File.join(@output_path, "src", "m5unified.c"))
    cpp_content = File.read(File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp"))

    # C++ defines function
    assert_includes cpp_content, "int m5unified_button_waspressed_void(void)"

    # C declares extern
    assert_includes c_content, "extern int m5unified_button_waspressed_void(void)"

    # C calls the function
    assert_includes c_content, "m5unified_button_waspressed_void()"
  end

  # Issue #3: Type-aware parameter extraction
  def test_float_parameter_conversion
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    test_data = [
      {
        name: "Sensor",
        methods: [
          {
            name: "setThreshold",
            return_type: "void",
            parameters: [
              { type: "float", name: "value" }
            ],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(test_data)

    c_content = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Should use GET_FLOAT_ARG for float parameter
    assert_includes c_content, "GET_FLOAT_ARG",
                    "Should use GET_FLOAT_ARG for float parameters"
    assert_includes c_content, "float value = GET_FLOAT_ARG(1)",
                    "Should extract float parameter correctly"
  end

  # Issue #3: Type-aware return value handling
  def test_float_return_conversion
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    test_data = [
      {
        name: "Sensor",
        methods: [
          {
            name: "getTemperature",
            return_type: "float",
            parameters: [],
            is_static: false,
            is_const: true,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(test_data)

    c_content = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Should use SET_FLOAT_RETURN for float return
    assert_includes c_content, "SET_FLOAT_RETURN",
                    "Should use SET_FLOAT_RETURN for float return values"
    assert_includes c_content, "float result = m5unified_sensor_gettemperature_void()",
                    "Should store float return value correctly"
  end

  # Integration: Multi-type method
  def test_mixed_type_method
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    test_data = [
      {
        name: "Display",
        methods: [
          {
            name: "drawCircle",
            return_type: "bool",
            parameters: [
              { type: "int", name: "x" },
              { type: "int", name: "y" },
              { type: "float", name: "radius" }
            ],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(test_data)

    c_content = File.read(File.join(@output_path, "src", "m5unified.c"))

    # Should use correct type for each parameter
    assert_includes c_content, "int x = GET_INT_ARG(1)",
                    "First int parameter should use GET_INT_ARG"
    assert_includes c_content, "int y = GET_INT_ARG(2)",
                    "Second int parameter should use GET_INT_ARG"
    assert_includes c_content, "float radius = GET_FLOAT_ARG(3)",
                    "Float parameter should use GET_FLOAT_ARG"

    # Bool return should use SET_BOOL_RETURN
    assert_includes c_content, "SET_BOOL_RETURN",
                    "Bool return should use SET_BOOL_RETURN"
  end
end
