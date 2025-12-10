# frozen_string_literal: true

require_relative "test_helper"

# Test M5LibGen::CppWrapperGenerator
class CppWrapperGeneratorTest < Test::Unit::TestCase
  def setup
    @simple_class_data = [
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
  end

  def test_generate_basic_wrapper
    generator = M5LibGen::CppWrapperGenerator.new(@simple_class_data)
    output = generator.generate

    assert_includes output, "#include <M5Unified.h>"
    assert_includes output, 'extern "C" {'
    assert_includes output, "} // extern \"C\""
  end

  def test_generate_function_with_no_parameters
    generator = M5LibGen::CppWrapperGenerator.new(@simple_class_data)
    output = generator.generate

    # Function name: m5unified_button_waspressed_void (no parameters)
    assert_includes output, "m5unified_button_waspressed_void(void)"
    # Bool return type converted to int
    assert_includes output, "int m5unified_button_waspressed_void"
    # API call
    assert_includes output, "M5.Button.wasPressed()"
  end

  def test_generate_function_with_parameters
    data_with_params = [
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

    generator = M5LibGen::CppWrapperGenerator.new(data_with_params)
    output = generator.generate

    # Function name with parameter types: m5unified_display_drawpixel_int_int
    assert_includes output, "m5unified_display_drawpixel_int_int"
    # Parameters in function signature
    assert_includes output, "int x, int y"
    # API call with parameters
    assert_includes output, "M5.Display.drawPixel(x, y)"
  end

  # Issue 1-1: Parameter names should not contain invalid characters
  def test_reject_invalid_parameter_names_with_dot
    data_with_invalid_params = [
      {
        name: "Display",
        methods: [
          {
            name: "configure",
            return_type: "int",
            parameters: [
              { type: "const config_t&", name: "cfg.atom_display" }  # Invalid name with dot
            ],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator = M5LibGen::CppWrapperGenerator.new(data_with_invalid_params)
    output = generator.generate

    # Should NOT generate invalid C++ code
    refute_match(/\(const config_t& cfg\.atom_display\)/, output,
                 "Generated code should not contain parameter name with '.'")

    # Should sanitize to valid parameter name
    assert_match(/\(const config_t& (cfg|param_0)\)/, output,
                 "Parameter name should be sanitized to 'cfg' or 'param_0'")
  end

  # Issue 1-2: Method overloading should generate unique function names
  def test_generate_unique_names_for_overloaded_methods
    data_with_overloads = [
      {
        name: "Display",
        methods: [
          {
            name: "dsp",
            return_type: "AtomDisplay",
            parameters: [{ type: "const atom_config_t&", name: "cfg" }],
            is_static: false,
            is_const: false,
            is_virtual: false
          },
          {
            name: "dsp",
            return_type: "ModuleDisplay",
            parameters: [{ type: "const module_config_t&", name: "cfg" }],
            is_static: false,
            is_const: false,
            is_virtual: false
          },
          {
            name: "dsp",
            return_type: "OLEDDisplay",
            parameters: [{ type: "const oled_config_t&", name: "cfg" }],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator = M5LibGen::CppWrapperGenerator.new(data_with_overloads)
    output = generator.generate

    # Extract all function names
    function_names = output.scan(/^(\w+)\s+m5unified_\w+\(/).flatten

    # All function names should be unique (no duplicate symbols)
    unique_names = output.scan(/m5unified_display_dsp_\w+/).uniq
    all_names = output.scan(/m5unified_display_dsp_\w+/)

    assert_equal all_names.size, unique_names.size,
                 "All overloaded methods should have unique function names. " \
                 "Found: #{all_names.inspect}"

    # Should have 3 distinct dsp wrapper functions
    dsp_functions = output.scan(/\w+\s+(m5unified_display_dsp_\w+)\(/)
    assert_equal 3, dsp_functions.size,
                 "Should generate 3 wrapper functions for 3 overloads"
  end

  def test_convert_bool_return_to_int
    generator = M5LibGen::CppWrapperGenerator.new(@simple_class_data)
    output = generator.generate

    # Bool return type should be converted to int
    assert_match(/int m5unified_button_waspressed/, output)
    # Return value should be converted: bool ? 1 : 0
    assert_match(/return .+ \? 1 : 0/, output)
  end

  def test_void_return_type
    data_with_void = [
      {
        name: "Display",
        methods: [
          {
            name: "clear",
            return_type: "void",
            parameters: [],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator = M5LibGen::CppWrapperGenerator.new(data_with_void)
    output = generator.generate

    # Void return type with _void suffix (no parameters)
    assert_includes output, "void m5unified_display_clear_void"
    # No return statement for void methods
    assert_match(/M5\.Display\.clear\(\);\s*\}/, output)
  end
end
