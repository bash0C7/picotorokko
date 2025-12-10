# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

# Test M5LibGen::MrbgemGenerator
class MrbgemGeneratorTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir("m5libgen_mrbgem_test")
    @output_path = File.join(@tmpdir, "mrbgem-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_initialize
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    assert_equal @output_path, generator.output_path
  end

  def test_generate_creates_directory_structure
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    simple_data = [
      {
        name: "TestClass",
        methods: [
          {
            name: "testMethod",
            return_type: "void",
            parameters: [],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(simple_data)

    assert Dir.exist?(@output_path), "Output directory should exist"
    assert Dir.exist?(File.join(@output_path, "mrblib")), "mrblib directory should exist"
    assert Dir.exist?(File.join(@output_path, "src")), "src directory should exist"
    assert Dir.exist?(File.join(@output_path, "ports", "esp32")), "ports/esp32 directory should exist"
  end

  def test_generate_creates_required_files
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    simple_data = [
      {
        name: "TestClass",
        methods: []
      }
    ]

    generator.generate(simple_data)

    assert File.exist?(File.join(@output_path, "mrbgem.rake")), "mrbgem.rake should exist"
    assert File.exist?(File.join(@output_path, "src", "m5unified.c")), "src/m5unified.c should exist"
    assert File.exist?(File.join(@output_path, "mrblib", "m5unified.rb")), "mrblib/m5unified.rb should exist"
    assert File.exist?(File.join(@output_path, "README.md")), "README.md should exist"
    assert File.exist?(File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp")),
                       "m5unified_wrapper.cpp should exist"
    assert File.exist?(File.join(@output_path, "CMakeLists.txt")), "CMakeLists.txt should exist"
  end

  # Issue 2-3: Filter unsupported methods
  def test_filter_methods_with_function_pointer_parameters
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    data_with_function_pointer = [
      {
        name: "EventHandler",
        methods: [
          {
            name: "setCallback",
            return_type: "void",
            parameters: [
              { type: "void (*callback)(int)", name: "cb" }  # Function pointer - unsupported
            ],
            is_static: false,
            is_const: false,
            is_virtual: false
          },
          {
            name: "start",
            return_type: "void",
            parameters: [],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(data_with_function_pointer)

    # Read generated wrapper
    wrapper_path = File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp")
    wrapper_content = File.read(wrapper_path)

    # Should NOT generate wrapper for setCallback (has function pointer parameter)
    refute_includes wrapper_content, "m5unified_eventhandler_setcallback",
                     "Should not generate wrapper for method with function pointer parameter"

    # Should generate wrapper for start (no unsupported types)
    assert_includes wrapper_content, "m5unified_eventhandler_start_void",
                    "Should generate wrapper for method without unsupported types"
  end

  def test_filter_methods_with_template_return_types
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    data_with_template = [
      {
        name: "Container",
        methods: [
          {
            name: "getItems",
            return_type: "std::vector<int>",  # Template return type - unsupported
            parameters: [],
            is_static: false,
            is_const: false,
            is_virtual: false
          },
          {
            name: "getCount",
            return_type: "int",
            parameters: [],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(data_with_template)

    # Read generated wrapper
    wrapper_path = File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp")
    wrapper_content = File.read(wrapper_path)

    # Should NOT generate wrapper for getItems (template return type)
    refute_includes wrapper_content, "m5unified_container_getitems",
                     "Should not generate wrapper for method with template return type"

    # Should generate wrapper for getCount (simple int return)
    assert_includes wrapper_content, "m5unified_container_getcount_void",
                    "Should generate wrapper for method with simple return type"
  end

  def test_filter_methods_with_rvalue_reference_parameters
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    data_with_rvalue = [
      {
        name: "Mover",
        methods: [
          {
            name: "move",
            return_type: "void",
            parameters: [
              { type: "Data&&", name: "data" }  # Rvalue reference - unsupported
            ],
            is_static: false,
            is_const: false,
            is_virtual: false
          },
          {
            name: "copy",
            return_type: "void",
            parameters: [
              { type: "const Data&", name: "data" }  # Normal reference - supported
            ],
            is_static: false,
            is_const: false,
            is_virtual: false
          }
        ]
      }
    ]

    generator.generate(data_with_rvalue)

    # Read generated wrapper
    wrapper_path = File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp")
    wrapper_content = File.read(wrapper_path)

    # Should NOT generate wrapper for move (rvalue reference parameter)
    refute_includes wrapper_content, "m5unified_mover_move",
                     "Should not generate wrapper for method with rvalue reference parameter"

    # Should generate wrapper for copy (normal reference)
    assert_includes wrapper_content, "m5unified_mover_copy",
                    "Should generate wrapper for method with normal reference"
  end

  def test_generate_returns_filtered_statistics
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    mixed_data = [
      {
        name: "Mixed",
        methods: [
          { name: "good1", return_type: "int", parameters: [],
            is_static: false, is_const: false, is_virtual: false },
          { name: "bad1", return_type: "void",
            parameters: [{ type: "void (*cb)()", name: "callback" }],
            is_static: false, is_const: false, is_virtual: false },
          { name: "good2", return_type: "bool", parameters: [],
            is_static: false, is_const: false, is_virtual: false },
          { name: "bad2", return_type: "std::function<void()>", parameters: [],
            is_static: false, is_const: false, is_virtual: false }
        ]
      }
    ]

    result = generator.generate(mixed_data)

    # Should return statistics about filtering
    assert_kind_of Hash, result, "generate() should return statistics hash"
    assert_equal 2, result[:filtered_count], "Should filter 2 unsupported methods"
    assert_equal 2, result[:generated_count], "Should generate 2 supported methods"
  end
end
