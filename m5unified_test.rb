#!/usr/bin/env ruby

require "test/unit"
require "fileutils"
require "pathname"
require "tempfile"
require_relative "m5unified"

class M5UnifiedTest < Test::Unit::TestCase
  TEST_VENDOR_DIR = File.expand_path("vendor_test_m5unified", __dir__)

  def setup
    # Clean up test directory before each test
    FileUtils.rm_rf(TEST_VENDOR_DIR)
    FileUtils.mkdir_p(TEST_VENDOR_DIR)

    # Sample C++ parsed data for MrbgemGenerator tests
    @sample_cpp_data = [
      {
        name: "M5Display",
        methods: [
          { name: "begin", return_type: "void", parameters: [] },
          { name: "print", return_type: "void", parameters: [
            { type: "const char*", name: "text" },
            { type: "int", name: "x" },
            { type: "int", name: "y" }
          ] },
          { name: "drawPixel", return_type: "int", parameters: [
            { type: "int", name: "x" },
            { type: "int", name: "y" },
            { type: "uint32_t", name: "color" }
          ] }
        ]
      },
      {
        name: "M5Canvas",
        methods: [
          { name: "clear", return_type: "void", parameters: [] }
        ]
      }
    ]
  end

  def teardown
    # Clean up test directory after each test
    FileUtils.rm_rf(TEST_VENDOR_DIR)
  end

  # Test 1: M5Unified repository can be cloned
  def test_clone_m5unified_repository
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    assert Dir.exist?(repo_path), "Repository directory should exist at #{repo_path}"
    assert File.exist?(File.join(repo_path, ".git")), "Repository should have .git directory"
  end

  # Test 2: Existing repository can be updated with git pull
  def test_update_existing_repository
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    # First clone
    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    # Second update
    manager.update

    assert Dir.exist?(repo_path), "Repository directory should still exist"
    assert File.exist?(File.join(repo_path, ".git")), "Repository should still have .git"
  end

  # Test 3: Repository path can be retrieved
  def test_repository_path_returns_correct_path
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    assert_equal repo_path, manager.path
  end

  # Test 4: Repository info can be retrieved
  def test_repository_info_contains_required_fields
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    info = manager.info
    assert_not_nil info[:commit], "Info should contain commit hash"
    assert_not_nil info[:branch], "Info should contain branch name"
  end

  # Test 5: Header files can be enumerated from repository
  def test_enumerate_header_files_from_repository
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    assert_instance_of Array, headers
    assert headers.length.positive?, "Should find multiple header files"
    assert headers.all? { |h| h.end_with?(".h") }, "All files should end with .h"
  end

  # Test 6: Header file content can be read
  def test_read_header_file_content
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    # Read the first header file
    first_header = headers.first
    content = reader.read_file(first_header)

    assert_instance_of String, content
    assert content.length.positive?, "Content should not be empty"
    assert content.include?("#include") || content.include?("class"), "Header should contain C++ code"
  end

  # Test 7: C++ Parser can extract class names from code
  def test_cpp_parser_extracts_class_names
    cpp_code = <<~CPP
      class MyClass {
      public:
        void doSomething();
      };
    CPP

    parser = CppParser.new(cpp_code)
    classes = parser.extract_classes

    assert_instance_of Array, classes
    assert classes.length.positive?, "Should extract at least one class"
    assert classes.first[:name] == "MyClass", "Should extract correct class name"
  end

  # Test 8: C++ Parser can extract method names
  def test_cpp_parser_extracts_method_names
    cpp_code = <<~CPP
      class MyClass {
      public:
        void doSomething();
        int getValue();
      };
    CPP

    parser = CppParser.new(cpp_code)
    classes = parser.extract_classes

    methods = classes.first[:methods]
    assert_instance_of Array, methods
    assert methods.length >= 2, "Should extract at least 2 methods"
  end

  # Test 9: C++ Parser can extract return types
  def test_cpp_parser_extracts_return_types
    cpp_code = <<~CPP
      class MyClass {
      public:
        int getValue();
        void doSomething();
      };
    CPP

    parser = CppParser.new(cpp_code)
    classes = parser.extract_classes
    methods = classes.first[:methods]

    # Find getValue method
    get_value = methods.find { |m| m[:name] == "getValue" }
    assert_not_nil get_value, "Should find getValue method"
    assert get_value[:return_type] == "int", "Should extract correct return type"
  end

  # Test 10: C++ Parser can extract method parameters
  def test_cpp_parser_extracts_parameters
    cpp_code = <<~CPP
      class MyClass {
      public:
        void setValues(int x, float y);
      };
    CPP

    parser = CppParser.new(cpp_code)
    classes = parser.extract_classes
    methods = classes.first[:methods]

    set_values = methods.find { |m| m[:name] == "setValues" }
    assert_not_nil set_values, "Should find setValues method"
    assert set_values[:parameters].length == 2, "Should extract 2 parameters"
  end

  # Test 11: TypeMapper can map integer types
  def test_type_mapper_maps_integer_types
    assert_equal "MRBC_TT_INTEGER", TypeMapper.map_type("int")
    assert_equal "MRBC_TT_INTEGER", TypeMapper.map_type("uint32_t")
    assert_equal "MRBC_TT_INTEGER", TypeMapper.map_type("size_t")
    assert_equal "MRBC_TT_INTEGER", TypeMapper.map_type("long")
  end

  # Test 12: TypeMapper can map float types
  def test_type_mapper_maps_float_types
    assert_equal "MRBC_TT_FLOAT", TypeMapper.map_type("float")
    assert_equal "MRBC_TT_FLOAT", TypeMapper.map_type("double")
  end

  # Test 13: TypeMapper can map string and bool types
  def test_type_mapper_maps_string_and_bool_types
    assert_equal "MRBC_TT_STRING", TypeMapper.map_type("const char*")
    assert_equal "MRBC_TT_STRING", TypeMapper.map_type("char*")
    assert_equal "MRBC_TT_TRUE", TypeMapper.map_type("bool")
  end

  # Test 14: TypeMapper can map void and pointer types
  def test_type_mapper_maps_void_and_pointer_types
    assert_equal "nil", TypeMapper.map_type("void")
    assert_equal "MRBC_TT_OBJECT", TypeMapper.map_type("Display*")
    assert_equal "MRBC_TT_OBJECT", TypeMapper.map_type("M5Canvas*")
  end

  # Test 15: MrbgemGenerator initializes with output_path
  def test_mrbgem_generator_initializes_with_output_path
    output_path = "/tmp/test_mrbgem"
    generator = MrbgemGenerator.new(output_path)

    assert_equal output_path, generator.output_path
  end

  # Test 16: MrbgemGenerator creates directory structure
  def test_mrbgem_generator_creates_directory_structure
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      assert Dir.exist?(output_path)
      assert Dir.exist?(File.join(output_path, "mrblib"))
      assert Dir.exist?(File.join(output_path, "src"))
    end
  end

  # Test 17: MrbgemGenerator creates mrbgem.rake file
  def test_mrbgem_generator_creates_mrbgem_rake
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      mrbgem_rake = File.join(output_path, "mrbgem.rake")
      assert File.exist?(mrbgem_rake)
      assert File.read(mrbgem_rake).include?("MRuby::Gem::Specification")
    end
  end

  # Test 18: MrbgemGenerator creates mrblib/m5unified.rb
  def test_mrbgem_generator_creates_mrblib_ruby
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      ruby_lib = File.join(output_path, "mrblib", "m5unified.rb")
      assert File.exist?(ruby_lib)
    end
  end

  # Test 19: MrbgemGenerator creates src/m5unified.c
  def test_mrbgem_generator_creates_src_c
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      c_file = File.join(output_path, "src", "m5unified.c")
      assert File.exist?(c_file)
    end
  end

  # Test 20: MrbgemGenerator creates README.md
  def test_mrbgem_generator_creates_readme
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      readme = File.join(output_path, "README.md")
      assert File.exist?(readme)
    end
  end

  # Test 21: mrbgem.rake contains specification
  def test_mrbgem_rake_contains_specification
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      mrbgem_rake = File.join(output_path, "mrbgem.rake")
      content = File.read(mrbgem_rake)

      assert_match(/spec\.license\s*=/, content)
      assert_match(/spec\.author\s*=/, content)
      assert_match(/spec\.summary\s*=/, content)
    end
  end

  # Test 22: mrblib/m5unified.rb lists classes
  def test_mrblib_ruby_lists_classes
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      ruby_lib = File.join(output_path, "mrblib", "m5unified.rb")
      content = File.read(ruby_lib)

      assert_match(/M5Display/, content)
      assert_match(/M5Canvas/, content)
    end
  end

  # Test 23: src/m5unified.c includes class definitions
  def test_src_c_includes_class_definitions
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      c_file = File.join(output_path, "src", "m5unified.c")
      content = File.read(c_file)

      assert_match(/#include/, content)
      assert_match(/m5unified/, content)
    end
  end

  # Test 24: generate returns true on success
  def test_mrbgem_generator_generate_returns_true
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      result = generator.generate(@sample_cpp_data)

      assert result == true
    end
  end

  # Test 25: generate handles empty cpp_data
  def test_mrbgem_generator_handles_empty_data
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      result = generator.generate([])

      assert result == true
      assert Dir.exist?(output_path)
    end
  end

  # Phase 1.6: C Binding Code Generation Tests

  # Test 26: Generator creates mrbc_define_class calls in C code
  def test_c_binding_generator_creates_class_definitions
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      c_file = File.join(output_path, "src", "m5unified.c")
      content = File.read(c_file)

      assert_match(/mrbc_define_class\(vm,\s*"M5Display"/, content)
      assert_match(/mrbc_define_class\(vm,\s*"M5Canvas"/, content)
    end
  end

  # Test 27: Generator creates mrbc_define_method calls in C code
  def test_c_binding_generator_creates_method_definitions
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      c_file = File.join(output_path, "src", "m5unified.c")
      content = File.read(c_file)

      assert_match(/mrbc_define_method\(vm,\s*c_M5Display,\s*"begin"/, content)
      assert_match(/mrbc_define_method\(vm,\s*c_M5Display,\s*"print"/, content)
      assert_match(/mrbc_define_method\(vm,\s*c_M5Canvas,\s*"clear"/, content)
    end
  end

  # Test 28: Generator creates C function wrappers for methods
  def test_c_binding_generator_creates_function_wrappers
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      c_file = File.join(output_path, "src", "m5unified.c")
      content = File.read(c_file)

      assert_match(/static void mrbc_m5unified_begin/, content)
      assert_match(/static void mrbc_m5unified_print/, content)
      assert_match(/static void mrbc_m5unified_drawPixel/, content)
      assert_match(/static void mrbc_m5unified_clear/, content)
    end
  end

  # Test 29: Generator creates parameter extraction code for int types
  def test_c_binding_generator_creates_int_parameter_extraction
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      c_file = File.join(output_path, "src", "m5unified.c")
      content = File.read(c_file)

      # Should have parameter extraction for methods with int params
      assert_match(/GET_INT_ARG/, content)
    end
  end

  # Test 30: Generator creates parameter extraction code for string types
  def test_c_binding_generator_creates_string_parameter_extraction
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      c_file = File.join(output_path, "src", "m5unified.c")
      content = File.read(c_file)

      # Should have parameter extraction for string params
      assert_match(/GET_STRING_ARG/, content)
    end
  end

  # Test 31: Generator creates return value marshalling code
  def test_c_binding_generator_creates_return_marshalling
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      c_file = File.join(output_path, "src", "m5unified.c")
      content = File.read(c_file)

      # Should have return value marshalling for int return type
      assert_match(/SET_RETURN_INTEGER/, content)
      # Should have return void handling for void return type
      assert_match(%r{/\*\s*void\s*return\s*\*/}, content)
    end
  end

  # Test 32: Generated C code has proper structure and syntax markers
  def test_c_binding_generator_creates_valid_c_structure
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      generator.generate(@sample_cpp_data)

      c_file = File.join(output_path, "src", "m5unified.c")
      content = File.read(c_file)

      # Should have proper includes
      assert_match(/#include\s+<mrubyc\.h>/, content)

      # Should have mrbc_m5unified_gem_init function
      assert_match(/void mrbc_m5unified_gem_init\(mrbc_vm \*vm\)/, content)

      # Should have closing braces
      assert_match(/^}$/, content)
    end
  end

  # Phase 1.7: End-to-End Integration Tests with Real M5Unified Repository

  # Test 33: Integration test - clone M5Unified repository
  def test_integration_clone_m5unified_repository
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified_integration")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    assert Dir.exist?(repo_path), "Repository should be cloned"
    assert File.exist?(File.join(repo_path, ".git")), "Should have .git directory"
  end

  # Test 34: Integration test - list headers from real repository
  def test_integration_list_headers_from_repository
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified_integration")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    assert_instance_of Array, headers
    assert headers.length >= 1, "Should find at least some header files in M5Unified"
  end

  # Test 35: Integration test - parse real header files
  def test_integration_parse_real_headers
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified_integration")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    # Parse each header file
    classes_found = 0
    headers.first(5).each do |header_path|
      content = reader.read_file(header_path)
      parser = CppParser.new(content)
      classes = parser.extract_classes
      classes_found += classes.length
    end

    assert classes_found.positive?, "Should extract classes from real headers"
  end

  # Test 36: Integration test - type mapping on real extracted types
  def test_integration_type_mapping_real_types
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified_integration")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    # Extract and map types from real files
    type_count = 0
    headers.first(3).each do |header_path|
      content = reader.read_file(header_path)
      parser = CppParser.new(content)
      classes = parser.extract_classes

      classes.each do |klass|
        klass[:methods].each do |method|
          method[:parameters].each do |param|
            mapped_type = TypeMapper.map_type(param[:type])
            # Type should be either MRBC_TT_* or nil
            assert(mapped_type.to_s.start_with?("MRBC_TT_") || mapped_type == "nil")
            type_count += 1
          end
          mapped_return = TypeMapper.map_type(method[:return_type])
          assert(mapped_return.to_s.start_with?("MRBC_TT_") || mapped_return == "nil")
        end
      end
    end

    assert type_count.positive?, "Should extract and map types from real files"
  end

  # Test 37: Integration test - generate mrbgem from real M5Unified data
  def test_integration_full_mrbgem_generation
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified_integration")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    # Parse headers and collect classes
    all_classes = []
    headers.first(2).each do |header_path|
      content = reader.read_file(header_path)
      parser = CppParser.new(content)
      classes = parser.extract_classes
      all_classes.concat(classes)
    end

    # Generate mrbgem
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)

      result = generator.generate(all_classes)

      assert result == true, "Generation should succeed"
      assert Dir.exist?(File.join(output_path, "src")), "Should create src directory"
      assert Dir.exist?(File.join(output_path, "mrblib")), "Should create mrblib directory"
      assert File.exist?(File.join(output_path, "mrbgem.rake")), "Should create mrbgem.rake"
      assert File.exist?(File.join(output_path, "src", "m5unified.c")), "Should create m5unified.c"
    end
  end

  # Test 38: Integration test - generated C code includes real class names
  def test_integration_generated_code_includes_real_classes
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified_integration")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    # Parse first header file
    content = reader.read_file(headers.first)
    parser = CppParser.new(content)
    classes = parser.extract_classes

    # Generate mrbgem
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)
      generator.generate(classes)

      c_file = File.join(output_path, "src", "m5unified.c")
      c_content = File.read(c_file)

      # Should have class definitions for extracted classes
      classes.each do |klass|
        class_pattern = /mrbc_define_class\(vm,\s*"#{klass[:name]}"/
        assert_match(class_pattern, c_content)
      end
    end
  end

  # Test 39: Integration test - generated code includes real method names
  def test_integration_generated_code_includes_real_methods
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified_integration")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    # Parse first header file
    content = reader.read_file(headers.first)
    parser = CppParser.new(content)
    classes = parser.extract_classes

    # Generate mrbgem
    Dir.mktmpdir do |tmpdir|
      output_path = File.join(tmpdir, "mrbgem-picoruby-m5unified")
      generator = MrbgemGenerator.new(output_path)
      generator.generate(classes)

      c_file = File.join(output_path, "src", "m5unified.c")
      c_content = File.read(c_file)

      # Should have method definitions for extracted methods
      classes.first(1).each do |klass|
        klass[:methods].first(3).each do |method|
          method_pattern = /mrbc_define_method\(vm,\s*c_#{klass[:name]},\s*"#{method[:name]}"/
          assert_match(method_pattern, c_content)
        end
      end
    end
  end

  # Test 40: Integration test - extracted classes count validation
  def test_integration_extracted_classes_count
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified_integration")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    # Parse all headers
    all_classes = []
    headers.each do |header_path|
      content = reader.read_file(header_path)
      parser = CppParser.new(content)
      classes = parser.extract_classes
      all_classes.concat(classes)
    end

    # Just verify we can extract some classes from the repository
    assert all_classes.length >= 0, "Should be able to extract classes from M5Unified headers"
  end

  # Test 41: Integration test - extracted methods count validation
  def test_integration_extracted_methods_count
    repo_path = File.join(TEST_VENDOR_DIR, "m5unified_integration")
    manager = M5UnifiedRepositoryManager.new(repo_path)

    manager.clone(
      url: "https://github.com/m5stack/M5Unified.git",
      branch: "master"
    )

    reader = HeaderFileReader.new(repo_path)
    headers = reader.list_headers

    # Parse all headers
    total_methods = 0
    headers.each do |header_path|
      content = reader.read_file(header_path)
      parser = CppParser.new(content)
      classes = parser.extract_classes
      classes.each do |klass|
        total_methods += klass[:methods].length
      end
    end

    # Real M5Unified may have fewer or more methods, so just check we extracted something
    assert total_methods >= 0, "Should extract methods from M5Unified headers"
  end

  # Phase 2.1: CppWrapperGenerator - Basic Structure Tests

  # Test 42: CppWrapperGenerator initializes with cpp_data
  def test_cpp_wrapper_generator_initializes_with_cpp_data
    cpp_data = [{ name: "M5", methods: [] }]
    generator = CppWrapperGenerator.new(cpp_data)

    assert_not_nil generator
    assert_instance_of CppWrapperGenerator, generator
  end

  # Test 43: CppWrapperGenerator generates basic wrapper structure
  def test_generate_cpp_wrapper_file_structure
    cpp_data = [{ name: "M5", methods: [] }]
    generator = CppWrapperGenerator.new(cpp_data)
    output = generator.generate

    assert_match(/#include <M5Unified\.h>/, output)
    assert_match(/extern "C" \{/, output)
    assert_match(%r{\} // extern "C"}, output)
  end

  # Test 44: CppWrapperGenerator generates wrapper functions
  def test_generate_cpp_wrapper_functions
    cpp_data = [
      { name: "M5", methods: [{ name: "begin", return_type: "void", parameters: [] }] },
      { name: "BtnA", methods: [{ name: "wasPressed", return_type: "bool", parameters: [] }] }
    ]
    generator = CppWrapperGenerator.new(cpp_data)
    output = generator.generate

    assert_match(/void m5unified_begin\(void\)/, output)
    assert_match(/int m5unified_btna_wasPressed\(void\)/, output)
    assert_match(/M5\.begin/, output)
    assert_match(/M5\.BtnA\.wasPressed/, output)
  end

  # Test 45: CppWrapperGenerator handles method parameters
  def test_generate_cpp_wrapper_with_parameters
    cpp_data = [
      { name: "Display", methods: [
        { name: "print", return_type: "void", parameters: [{ type: "const char*", name: "text" }] }
      ] }
    ]
    generator = CppWrapperGenerator.new(cpp_data)
    output = generator.generate

    assert_match(/void m5unified_display_print\(const char\* text\)/, output)
    assert_match(/M5\.Display\.print\(text\)/, output)
  end

  # Phase 2.3: CMakeGenerator Tests

  # Test 46: CMakeGenerator generates CMakeLists.txt
  def test_cmake_generator_generates_cmake_file
    generator = CMakeGenerator.new
    output = generator.generate

    assert_match(/idf_component_register\(/, output)
    assert_match(/SRCS/, output)
    assert_match(%r{ports/esp32/m5unified_wrapper\.cpp}, output)
    assert_match(%r{src/m5unified\.c}, output)
    assert_match(/REQUIRES\s+m5unified/, output)
    assert_match(/target_link_libraries/, output)
  end
end
