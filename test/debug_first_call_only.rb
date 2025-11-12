#!/usr/bin/env ruby
# frozen_string_literal: true

# 最初の tasks 呼び出しのみ問題が発生するか確認

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

# [実験 1] respond_to? を呼んで、最初の tasks を呼ぶ
puts "[実験 1] respond_to? + 最初の tasks 呼び出し"
source1 = "task :build do; end"
result1 = Prism.parse(source1)
extractor1 = Picotorokko::Commands::RakeTaskExtractor.new
result1.value.accept(extractor1)

before1 = ObjectSpace.count_objects
_ = Test::Unit::AutoRunner.respond_to?(:need_run?)
_ = extractor1.tasks
after1 = ObjectSpace.count_objects
puts "  TOTAL 変化: +#{after1[:TOTAL] - before1[:TOTAL]}, T_CLASS 変化: +#{after1[:T_CLASS] - before1[:T_CLASS]}"

# [実験 2] 2 回目の tasks 呼び出し（respond_to? を再度呼ぶ）
puts "\n[実験 2] respond_to? + 2 回目の tasks 呼び出し"
source2 = "task :build do; end"
result2 = Prism.parse(source2)
extractor2 = Picotorokko::Commands::RakeTaskExtractor.new
result2.value.accept(extractor2)

before2 = ObjectSpace.count_objects
_ = Test::Unit::AutoRunner.respond_to?(:need_run?)
_ = extractor2.tasks
after2 = ObjectSpace.count_objects
puts "  TOTAL 変化: +#{after2[:TOTAL] - before2[:TOTAL]}, T_CLASS 変化: +#{after2[:T_CLASS] - before2[:T_CLASS]}"

# [実験 3] 3 回目の tasks 呼び出し（respond_to? なし）
puts "\n[実験 3] 3 回目の tasks 呼び出し（respond_to? なし）"
source3 = "task :build do; end"
result3 = Prism.parse(source3)
extractor3 = Picotorokko::Commands::RakeTaskExtractor.new
result3.value.accept(extractor3)

before3 = ObjectSpace.count_objects
_ = extractor3.tasks
after3 = ObjectSpace.count_objects
puts "  TOTAL 変化: +#{after3[:TOTAL] - before3[:TOTAL]}, T_CLASS 変化: +#{after3[:T_CLASS] - before3[:T_CLASS]}"
