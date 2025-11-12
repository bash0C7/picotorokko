#!/usr/bin/env ruby
# frozen_string_literal: true

# 最小再現コード：extractor.tasks が test-unit registration を破壊する

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "test-unit"
require "prism"
require "picotorokko/commands/device"

puts "=" * 80
puts "最小再現実験"
puts "=" * 80

# ダミーテストクラス1（rake_task_extractor_test.rb の代わり）
class DummyTest1 < Test::Unit::TestCase
  def test_with_tasks_call
    source = "task :build do; end"
    result = Prism.parse(source)
    extractor = Picotorokko::Commands::RakeTaskExtractor.new
    result.value.accept(extractor)

    # 問題の核心：extractor.tasks を呼ぶ
    tasks = extractor.tasks
    assert_equal(["build"], tasks)
  end
end

# ダミーテストクラス2（env_test.rb の代わり）
class DummyTest2 < Test::Unit::TestCase
  def test_dummy
    assert_true(true)
  end

  def test_another_dummy
    assert_equal(1, 1)
  end
end

puts "\n定義されたテストクラス:"
ObjectSpace.each_object(Class).select do |k|
  begin
    k < Test::Unit::TestCase && k.name && k.name.start_with?("Dummy")
  rescue StandardError
    false
  end
end.each do |test_case|
  test_methods = test_case.public_instance_methods(false).grep(/^test_/)
  puts "  #{test_case.name}: #{test_methods.size} tests"
end

puts "\nテスト実行開始..."
