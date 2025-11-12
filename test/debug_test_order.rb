#!/usr/bin/env ruby
# frozen_string_literal: true

# テスト実行順序と registration を追跡

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# TracePoint でテストクラスの定義を追跡
classes_defined = []
trace = TracePoint.new(:end) do |tp|
  if tp.self.is_a?(Class)
    begin
      if tp.self < Test::Unit::TestCase
        classes_defined << { name: tp.self.name, location: tp.path }
      end
    rescue StandardError
      # Ignore
    end
  end
end

trace.enable

# test_helper をロード
require_relative "test_helper"

# rake_task_extractor_test.rb をロード
puts "[ロード] rake_task_extractor_test.rb"
require "picotorokko/commands/device"
require_relative "rake_task_extractor_test"
puts "  定義されたテストクラス: #{classes_defined.map { |c| c[:name] }.join(', ')}"

# env_test.rb をロード
puts "\n[ロード] env_test.rb"
before_env = classes_defined.size
require_relative "env_test"
after_env = classes_defined.size
puts "  新しく定義されたテストクラス数: #{after_env - before_env}"
puts "  定義されたテストクラス: #{classes_defined[before_env..-1].map { |c| c[:name] }.join(', ')}"

trace.disable

# Test::Unit が認識しているテストを確認
puts "\n[Test::Unit が認識しているテストケース]"
ObjectSpace.each_object(Class).select do |k|
  begin
    k < Test::Unit::TestCase && k.name
  rescue StandardError
    false
  end
end.each do |test_case|
  test_methods = test_case.public_instance_methods(false).grep(/^test_/)
  puts "  #{test_case.name}: #{test_methods.size} tests"
end

puts "\n[テスト実行開始]"
# Test::Unit に実行させる
exit Test::Unit::AutoRunner.run
