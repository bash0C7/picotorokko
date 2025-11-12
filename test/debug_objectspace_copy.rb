#!/usr/bin/env ruby
# frozen_string_literal: true

# ObjectSpace 追跡実験：extractor.tasks メソッド呼び出しが test-unit に与える影響を調査

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"

puts "=" * 80
puts "ObjectSpace 追跡実験開始"
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

# at_exit hook の登録状況を確認
puts "\n[3] at_exit hook 登録状況"
# Test::Unit::AutoRunner が at_exit に登録されているか確認
# （残念ながら Ruby の at_exit hook は直接調査できないが、Test::Unit のソースを追う）
puts "  Test::Unit::AutoRunner クラス存在: #{defined?(Test::Unit::AutoRunner) ? 'Yes' : 'No'}"

# RakeTaskExtractor インスタンス作成前
puts "\n[4] RakeTaskExtractor インスタンス作成前"
before_extractor = {
  objects: ObjectSpace.count_objects,
  classes: ObjectSpace.each_object(Class).count
}
puts "  オブジェクト数: #{before_extractor[:objects][:TOTAL]}"
puts "  クラス数: #{before_extractor[:classes]}"

# RakeTaskExtractor インスタンス作成
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new

puts "\n[5] RakeTaskExtractor インスタンス作成後、accept 前"
after_extractor_new = {
  objects: ObjectSpace.count_objects,
  classes: ObjectSpace.each_object(Class).count
}
puts "  オブジェクト数: #{after_extractor_new[:objects][:TOTAL]}"
puts "  クラス数: #{after_extractor_new[:classes]}"

# accept 呼び出し
result.value.accept(extractor)

puts "\n[6] accept 呼び出し後、tasks メソッド呼び出し前"
after_accept = {
  objects: ObjectSpace.count_objects,
  classes: ObjectSpace.each_object(Class).count
}
puts "  オブジェクト数: #{after_accept[:objects][:TOTAL]}"
puts "  クラス数: #{after_accept[:classes]}"

# ここで instance_variable_get を使った場合（安全）
puts "\n[7] instance_variable_get 呼び出し（安全な方法）"
tasks_via_ivar = extractor.instance_variable_get(:@tasks)
puts "  取得したタスク: #{tasks_via_ivar.inspect}"
after_ivar_get = {
  objects: ObjectSpace.count_objects,
  classes: ObjectSpace.each_object(Class).count
}
puts "  オブジェクト数: #{after_ivar_get[:objects][:TOTAL]}"
puts "  クラス数: #{after_ivar_get[:classes]}"

# tasks メソッド呼び出し（危険）
puts "\n[8] tasks メソッド呼び出し（危険な方法）"
puts "  呼び出し前の Test::Unit::AutoRunner.need_run?: #{Test::Unit::AutoRunner.need_run?}" if Test::Unit::AutoRunner.respond_to?(:need_run?)
tasks_via_method = extractor.tasks
puts "  取得したタスク: #{tasks_via_method.inspect}"
puts "  呼び出し後の Test::Unit::AutoRunner.need_run?: #{Test::Unit::AutoRunner.need_run?}" if Test::Unit::AutoRunner.respond_to?(:need_run?)
after_tasks_call = {
  objects: ObjectSpace.count_objects,
  classes: ObjectSpace.each_object(Class).count
}
puts "  オブジェクト数: #{after_tasks_call[:objects][:TOTAL]}"
puts "  クラス数: #{after_tasks_call[:classes]}"

# 変化の差分を表示
puts "\n" + "=" * 80
puts "変化の差分"
puts "=" * 80
puts "[instance_variable_get 前→後]"
puts "  オブジェクト数変化: #{after_ivar_get[:objects][:TOTAL] - after_accept[:objects][:TOTAL]}"
puts "  クラス数変化: #{after_ivar_get[:classes] - after_accept[:classes]}"

puts "\n[tasks メソッド呼び出し 前→後]"
puts "  オブジェクト数変化: #{after_tasks_call[:objects][:TOTAL] - after_ivar_get[:objects][:TOTAL]}"
puts "  クラス数変化: #{after_tasks_call[:classes] - after_ivar_get[:classes]}"

puts "\n実験終了（at_exit hook はこの後実行される）"
