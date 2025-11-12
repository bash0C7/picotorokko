#!/usr/bin/env ruby
# frozen_string_literal: true

# 二分探索：puts 文と ObjectSpace 記録を段階的に追加

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"

puts "=" * 80
puts "実験開始"
puts "=" * 80

# Test::Unit のロード前の状態を記録
puts "\n[1] Test::Unit ロード前"
before_test_unit = {
  objects: ObjectSpace.count_objects,
  classes: ObjectSpace.each_object(Class).count
}
puts "  オブジェクト数: #{before_test_unit[:objects][:TOTAL]}"
puts "  クラス数: #{before_test_unit[:classes]}"

# Test::Unit をロード
require "test-unit"
puts "\n[2] Test::Unit ロード後"
after_test_unit = {
  objects: ObjectSpace.count_objects,
  classes: ObjectSpace.each_object(Class).count
}
puts "  オブジェクト数: #{after_test_unit[:objects][:TOTAL]}"
puts "  クラス数: #{after_test_unit[:classes]}"

# RakeTaskExtractor インスタンス作成
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor)

# instance_variable_get 呼び出し
tasks_via_ivar = extractor.instance_variable_get(:@tasks)

# tasks メソッド呼び出し前
before = ObjectSpace.count_objects

# tasks メソッド呼び出し
tasks_via_method = extractor.tasks

# tasks メソッド呼び出し後
after = ObjectSpace.count_objects

# 結果表示
puts "\ntasks メソッド呼び出し前後の ObjectSpace 変化:"
puts "  TOTAL: #{before[:TOTAL]} → #{after[:TOTAL]} (+#{after[:TOTAL] - before[:TOTAL]})"
puts "  T_CLASS: #{before[:T_CLASS]} → #{after[:T_CLASS]} (+#{after[:T_CLASS] - before[:T_CLASS]})"
