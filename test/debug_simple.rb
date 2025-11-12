#!/usr/bin/env ruby
# frozen_string_literal: true

# 最もシンプルな実験：tasks メソッド呼び出し前後の ObjectSpace 変化

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

# RakeTaskExtractor インスタンス作成
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor)

# tasks メソッド呼び出し前
before = ObjectSpace.count_objects

# tasks メソッド呼び出し
_ = extractor.tasks

# tasks メソッド呼び出し後
after = ObjectSpace.count_objects

# 結果表示
puts "tasks メソッド呼び出し前後の ObjectSpace 変化:"
puts "  TOTAL: #{before[:TOTAL]} → #{after[:TOTAL]} (+#{after[:TOTAL] - before[:TOTAL]})"
puts "  T_CLASS: #{before[:T_CLASS]} → #{after[:T_CLASS]} (+#{after[:T_CLASS] - before[:T_CLASS]})"
puts "  T_MODULE: #{before[:T_MODULE]} → #{after[:T_MODULE]} (+#{after[:T_MODULE] - before[:T_MODULE]})"
