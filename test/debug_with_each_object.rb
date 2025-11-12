#!/usr/bin/env ruby
# frozen_string_literal: true

# ObjectSpace.each_object(Class).count の影響を確認

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

# RakeTaskExtractor インスタンス作成
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor)

# [実験 1] ObjectSpace.each_object(Class).count を呼び出してから tasks を呼ぶ
puts "[実験 1] ObjectSpace.each_object(Class).count を事前に呼び出す"
before1 = ObjectSpace.count_objects
class_count = ObjectSpace.each_object(Class).count
puts "  クラス数: #{class_count}"

# tasks メソッド呼び出し
_ = extractor.tasks

after1 = ObjectSpace.count_objects
puts "  TOTAL 変化: #{before1[:TOTAL]} → #{after1[:TOTAL]} (+#{after1[:TOTAL] - before1[:TOTAL]})"
puts "  T_CLASS 変化: #{before1[:T_CLASS]} → #{after1[:T_CLASS]} (+#{after1[:T_CLASS] - before1[:T_CLASS]})"
