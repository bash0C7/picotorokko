#!/usr/bin/env ruby

require "test/unit"
require "fileutils"
require "pathname"
require_relative "m5unified"

class M5UnifiedTest < Test::Unit::TestCase
  TEST_VENDOR_DIR = File.expand_path("vendor_test_m5unified", __dir__)

  def setup
    # Clean up test directory before each test
    FileUtils.rm_rf(TEST_VENDOR_DIR)
    FileUtils.mkdir_p(TEST_VENDOR_DIR)
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
end
