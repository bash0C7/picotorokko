#!/usr/bin/env ruby
# frozen_string_literal: true

# Test::Unit registration 状態を確認

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "test-unit"
require_relative "test_helper"

puts "[1] test-unit ロード直後の状態"
puts "  Test::Unit::TestCase.test_defined?: #{Test::Unit::TestCase.respond_to?(:test_defined?)}"
puts "  ObjectSpace.each_object(Class).count(Test::Unit::TestCase): #{ObjectSpace.each_object(Class).count { |k| k < Test::Unit::TestCase rescue false }}"

# rake_task_extractor_test.rb をロード
puts "\n[2] rake_task_extractor_test.rb をロード"
require "picotorokko/commands/device"
require_relative "rake_task_extractor_test"

puts "  TestCase サブクラス数: #{ObjectSpace.each_object(Class).count { |k| k < Test::Unit::TestCase rescue false }}"
puts "  RakeTaskExtractorTest 存在: #{defined?(RakeTaskExtractorTest) ? 'Yes' : 'No'}"

# env_test.rb をロード
puts "\n[3] env_test.rb をロード"
require_relative "env_test"

puts "  TestCase サブクラス数: #{ObjectSpace.each_object(Class).count { |k| k < Test::Unit::TestCase rescue false }}"
puts "  PraCommandsEnvTest 存在: #{defined?(PraCommandsEnvTest) ? 'Yes' : 'No'}"

# Test::Unit が認識しているテスト一覧を確認
puts "\n[4] Test::Unit が認識しているテストケース"
test_cases = ObjectSpace.each_object(Class).select { |k| k < Test::Unit::TestCase && k.name rescue false }
test_cases.each do |test_case|
  test_methods = test_case.public_instance_methods(false).grep(/^test_/)
  puts "  #{test_case.name}: #{test_methods.size} tests"
end
