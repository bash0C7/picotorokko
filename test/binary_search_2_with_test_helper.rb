#!/usr/bin/env ruby
# frozen_string_literal: true

# Binary Search Step 2: test_helper を追加

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require_relative "test_helper"
require "picotorokko/commands/device"

# RakeTaskExtractor の単体テスト（test_helper あり）
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

  private

  def extract_tasks(source)
    result = Prism.parse(source)
    extractor = Picotorokko::Commands::RakeTaskExtractor.new
    result.value.accept(extractor)
    extractor
  end
end

# ダミー env_test
class EnvDummyTest < PraTestCase
  def test_dummy1
    assert_true(true)
  end

  def test_dummy2
    assert_equal(1, 1)
  end
end
