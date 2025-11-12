#!/usr/bin/env ruby
# frozen_string_literal: true

# instance_variable_get → tasks の呼び出し順序の影響を確認

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

puts "[実験 1] instance_variable_get を先に呼んでから tasks を呼ぶ"
source = "task :build do; end"
result = Prism.parse(source)
extractor1 = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor1)

# instance_variable_get 呼び出し
_ = extractor1.instance_variable_get(:@tasks)

# tasks メソッド呼び出し前の状態
before1 = ObjectSpace.count_objects

# tasks メソッド呼び出し
_ = extractor1.tasks

after1 = ObjectSpace.count_objects
puts "  TOTAL 変化: #{before1[:TOTAL]} → #{after1[:TOTAL]} (+#{after1[:TOTAL] - before1[:TOTAL]})"
puts "  T_CLASS 変化: #{before1[:T_CLASS]} → #{after1[:T_CLASS]} (+#{after1[:T_CLASS] - before1[:T_CLASS]})"

puts "\n[実験 2] tasks を直接呼ぶ（instance_variable_get なし）"
source2 = "task :build do; end"
result2 = Prism.parse(source2)
extractor2 = Picotorokko::Commands::RakeTaskExtractor.new
result2.value.accept(extractor2)

# tasks メソッド呼び出し前の状態
before2 = ObjectSpace.count_objects

# tasks メソッド呼び出し
_ = extractor2.tasks

after2 = ObjectSpace.count_objects
puts "  TOTAL 変化: #{before2[:TOTAL]} → #{after2[:TOTAL]} (+#{after2[:TOTAL] - before2[:TOTAL]})"
puts "  T_CLASS 変化: #{before2[:T_CLASS]} → #{after2[:T_CLASS]} (+#{after2[:T_CLASS] - before2[:T_CLASS]})"
