#!/usr/bin/env ruby
# frozen_string_literal: true

# 最初の extractor のみで実験（他の extractor の影響を排除）

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

# 最初の extractor のみ作成
puts "[実験] 最初の extractor のみで respond_to? を呼ぶ"
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor)

before = ObjectSpace.count_objects
_ = Test::Unit::AutoRunner.respond_to?(:need_run?)
_ = extractor.tasks
after = ObjectSpace.count_objects
puts "  TOTAL 変化: +#{after[:TOTAL] - before[:TOTAL]}, T_CLASS 変化: +#{after[:T_CLASS] - before[:T_CLASS]}"
