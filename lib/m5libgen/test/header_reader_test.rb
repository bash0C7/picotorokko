# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

# Test M5LibGen::HeaderReader
class HeaderReaderTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir("m5libgen_test")
    @repo_path = File.join(@tmpdir, "test_repo")
    FileUtils.mkdir_p(@repo_path)

    # Create test header files
    create_test_headers
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_initialize
    reader = M5LibGen::HeaderReader.new(@repo_path)
    assert_equal @repo_path, reader.repo_path
  end

  def test_list_headers_in_src_directory
    reader = M5LibGen::HeaderReader.new(@repo_path)
    headers = reader.list_headers

    assert(headers.any? { |h| h.include?("src/example.h") })
    assert(headers.any? { |h| h.include?("src/subfolder/nested.h") })
  end

  def test_list_headers_in_include_directory
    reader = M5LibGen::HeaderReader.new(@repo_path)
    headers = reader.list_headers

    assert(headers.any? { |h| h.include?("include/public.h") })
  end

  def test_list_headers_excludes_cpp_files
    reader = M5LibGen::HeaderReader.new(@repo_path)
    headers = reader.list_headers

    assert(headers.none? { |h| h.end_with?(".cpp") })
  end

  def test_list_headers_returns_sorted_paths
    reader = M5LibGen::HeaderReader.new(@repo_path)
    headers = reader.list_headers

    assert_equal headers.sort, headers
  end

  def test_read_file_returns_content
    reader = M5LibGen::HeaderReader.new(@repo_path)
    file_path = File.join(@repo_path, "src", "example.h")
    content = reader.read_file(file_path)

    assert_equal "// Example header\n", content
  end

  def test_read_file_raises_error_if_file_does_not_exist
    reader = M5LibGen::HeaderReader.new(@repo_path)
    file_path = File.join(@repo_path, "nonexistent.h")

    assert_raise(M5LibGen::HeaderReader::FileNotFoundError) do
      reader.read_file(file_path)
    end
  end

  private

  def create_test_headers
    # Create src/ directory with headers
    FileUtils.mkdir_p(File.join(@repo_path, "src", "subfolder"))
    File.write(File.join(@repo_path, "src", "example.h"), "// Example header\n")
    File.write(File.join(@repo_path, "src", "subfolder", "nested.h"), "// Nested header\n")

    # Create include/ directory with headers
    FileUtils.mkdir_p(File.join(@repo_path, "include"))
    File.write(File.join(@repo_path, "include", "public.h"), "// Public header\n")

    # Create .cpp file (should be ignored)
    File.write(File.join(@repo_path, "src", "example.cpp"), "// C++ source\n")
  end
end
