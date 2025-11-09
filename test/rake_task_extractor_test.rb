$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require_relative "test_helper"
require "pra/commands/device"

# RakeTaskExtractor の単体テスト
class RakeTaskExtractorTest < PraTestCase
  def test_simple_task_definition_with_symbol
    source = "task :build do; end"
    extractor = extract_tasks(source)
    assert_equal(["build"], extractor.tasks)
  end

  def test_simple_task_definition_with_string
    source = 'task "build" do; end'
    extractor = extract_tasks(source)
    assert_equal(["build"], extractor.tasks)
  end

  def test_multiple_simple_tasks
    source = <<~RUBY
      task :build do; end
      task "clean" do; end
      task :test do; end
    RUBY
    extractor = extract_tasks(source)
    assert_equal(%w[build clean test], extractor.tasks.sort)
  end

  def test_word_array_with_each_expansion
    source = <<~RUBY
      %w[esp32 esp32c3 esp32s3].each do |chip|
        task "setup_\#{chip}" do; end
      end
    RUBY
    extractor = extract_tasks(source)
    assert_equal(%w[setup_esp32 setup_esp32c3 setup_esp32s3], extractor.tasks.sort)
  end

  def test_regular_array_with_each_expansion
    source = <<~RUBY
      ['debug', 'release'].each do |mode|
        task "build_\#{mode}" do; end
      end
    RUBY
    extractor = extract_tasks(source)
    assert_equal(["build_debug", "build_release"], extractor.tasks.sort)
  end

  def test_each_with_prefix_and_suffix
    source = <<~RUBY
      %w[a b c].each do |letter|
        task "test_\#{letter}_all" do; end
      end
    RUBY
    extractor = extract_tasks(source)
    assert_equal(%w[test_a_all test_b_all test_c_all], extractor.tasks.sort)
  end

  def test_multiple_tasks_in_each_block
    source = <<~RUBY
      %w[esp32 esp32c3].each do |chip|
        task "build_\#{chip}" do; end
        task "flash_\#{chip}" do; end
      end
    RUBY
    extractor = extract_tasks(source)
    expected = %w[build_esp32 build_esp32c3 flash_esp32 flash_esp32c3]
    assert_equal(expected.sort, extractor.tasks.sort)
  end

  def test_mixed_static_and_dynamic_tasks
    source = <<~RUBY
      task :clean do; end
      %w[esp32 esp32c3].each do |chip|
        task "setup_\#{chip}" do; end
      end
      task "all" do; end
    RUBY
    extractor = extract_tasks(source)
    expected = %w[all clean setup_esp32 setup_esp32c3]
    assert_equal(expected, extractor.tasks.sort)
  end

  def test_duplicate_tasks_are_deduplicated
    source = <<~RUBY
      task :build do; end
      task "build" do; end
    RUBY
    extractor = extract_tasks(source)
    assert_equal(["build", "build"], extractor.tasks)
    # NOTE: deduplication happens in available_rake_tasks, not in extractor itself
    # This allows the extractor to be simple and let the caller decide on deduplication
  end

  def test_runtime_interpolation_is_skipped
    source = <<~RUBY
      mode = 'release'
      task "build_\#{mode}" do; end
    RUBY
    extractor = extract_tasks(source)
    # Runtime interpolation cannot be statically analyzed
    assert_equal([], extractor.tasks)
  end

  def test_constant_based_arrays_are_skipped
    source = <<~RUBY
      CHIPS = %w[esp32 esp32c3]
      CHIPS.each do |chip|
        task "setup_\#{chip}" do; end
      end
    RUBY
    extractor = extract_tasks(source)
    # Cannot resolve constants at static analysis time
    assert_equal([], extractor.tasks)
  end

  def test_method_call_results_are_skipped
    source = <<~RUBY
      get_chips.each do |chip|
        task "build_\#{chip}" do; end
      end
    RUBY
    extractor = extract_tasks(source)
    # Cannot resolve method results at static analysis time
    assert_equal([], extractor.tasks)
  end

  def test_empty_file
    source = ""
    extractor = extract_tasks(source)
    assert_equal([], extractor.tasks)
  end

  def test_file_with_no_tasks
    source = <<~RUBY
      def helper_method
        puts "hello"
      end
    RUBY
    extractor = extract_tasks(source)
    assert_equal([], extractor.tasks)
  end

  private

  def extract_tasks(source)
    result = Prism.parse(source)
    extractor = Pra::Commands::RakeTaskExtractor.new
    result.value.accept(extractor)
    extractor
  end
end
