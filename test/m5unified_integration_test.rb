# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/m5libgen/lib/m5libgen/repository_manager"
require_relative "../lib/m5libgen/lib/m5libgen/header_reader"
require_relative "../lib/m5libgen/lib/m5libgen/libclang_parser"
require_relative "../lib/m5libgen/lib/m5libgen/mrbgem_generator"
require_relative "../lib/m5libgen/lib/m5libgen/cpp_wrapper_generator"
require_relative "../lib/m5libgen/lib/m5libgen/cmake_generator"
require "tmpdir"
require "fileutils"

# End-to-end integration test with real M5Unified repository
class M5UnifiedIntegrationTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir("m5unified_integration_test")
    @repo_path = File.join(@tmpdir, "m5unified")
    @output_path = File.join(@tmpdir, "mrbgem-output")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_clone_m5unified_repository
    repo = M5LibGen::RepositoryManager.new(@repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    assert Dir.exist?(@repo_path)
    assert Dir.exist?(File.join(@repo_path, ".git"))
    assert File.exist?(File.join(@repo_path, "src", "M5Unified.h"))
  end

  def test_extract_button_class_methods
    omit "Skipping slow integration test" unless ENV["RUN_INTEGRATION_TESTS"]

    repo = M5LibGen::RepositoryManager.new(@repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Find Button_Class.hpp
    header_reader = M5LibGen::HeaderReader.new(@repo_path)
    button_header = header_reader.list_headers.find { |h| h.include?("Button_Class.hpp") }
    assert_not_nil button_header, "Button_Class.hpp should exist"

    # Parse Button_Class
    parser = M5LibGen::LibClangParser.new(button_header, include_paths: [File.join(@repo_path, "src")])
    classes = parser.extract_classes

    button_class = classes.find { |c| c[:name] == "Button_Class" }
    assert_not_nil button_class, "Button_Class should be extracted"

    # Button_Class should have many methods (24+ expected)
    assert button_class[:methods].length >= 20,
           "Button_Class should have at least 20 methods, got #{button_class[:methods].length}"

    # Check for specific methods
    method_names = button_class[:methods].map { |m| m[:name] }
    assert_includes method_names, "wasClicked", "Should have wasClicked method"
    assert_includes method_names, "wasPressed", "Should have wasPressed method"
    assert_includes method_names, "isHolding", "Should have isHolding method"
  end

  def test_generate_complete_mrbgem
    omit "Skipping slow integration test" unless ENV["RUN_INTEGRATION_TESTS"]

    repo = M5LibGen::RepositoryManager.new(@repo_path)
    repo.clone(url: "https://github.com/m5stack/M5Unified.git")

    # Read all headers
    header_reader = M5LibGen::HeaderReader.new(@repo_path)
    headers = header_reader.list_headers

    # Parse all classes
    all_classes = []
    headers.each do |header|
      next if header.include?("lgfx") # Skip LovyanGFX for now

      parser = M5LibGen::LibClangParser.new(header, include_paths: [File.join(@repo_path, "src")])
      classes = parser.extract_classes
      all_classes.concat(classes)
    end

    # Should extract many classes (30+ expected)
    assert all_classes.length >= 20,
           "Should extract at least 20 classes, got #{all_classes.length}"

    # Should extract many methods total (200+ expected)
    total_methods = all_classes.sum { |c| c[:methods].length }
    assert total_methods >= 100,
           "Should extract at least 100 methods total, got #{total_methods}"

    # Generate mrbgem
    generator = M5LibGen::MrbgemGenerator.new(@output_path)
    generator.generate(all_classes)

    # Verify generated files exist
    assert File.exist?(File.join(@output_path, "mrbgem.rake"))
    assert File.exist?(File.join(@output_path, "src", "m5unified.c"))
    assert File.exist?(File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp"))
    assert File.exist?(File.join(@output_path, "CMakeLists.txt"))

    # Verify generated C code has no TODO stubs
    c_file = File.read(File.join(@output_path, "src", "m5unified.c"))
    refute_match(%r{/\* TODO: Call wrapper function \*/}, c_file,
                 "Should not have TODO stubs in generated code")

    # Verify generated C++ code has proper syntax
    cpp_file = File.read(File.join(@output_path, "ports", "esp32", "m5unified_wrapper.cpp"))
    refute_match(/void void/, cpp_file, "Should not have 'void void' syntax errors")
    refute_match(/\.\.\. \.\.\./, cpp_file, "Should not have '... ...' syntax errors")
  end
end
