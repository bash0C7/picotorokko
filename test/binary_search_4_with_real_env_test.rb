#!/usr/bin/env ruby
# frozen_string_literal: true

# Binary Search Step 4: 実際の env_test.rb をロード

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require_relative "test_helper"
require "picotorokko/commands/device"

# RakeTaskExtractor の単体テスト（簡略版）
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

# 実際の env_test.rb をロード
require_relative "env_test"
