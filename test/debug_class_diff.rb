#!/usr/bin/env ruby
# frozen_string_literal: true

# クラス差分追跡：tasks メソッド呼び出し前後でどのクラスが増えたか

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

puts "=" * 80
puts "クラス差分追跡実験"
puts "=" * 80

# RakeTaskExtractor インスタンス作成
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor)

puts "\n[準備完了] extractor インスタンス作成、accept 呼び出し済み"

# tasks メソッド呼び出し前のクラス一覧を取得
puts "\n[1] tasks メソッド呼び出し前のクラス一覧を取得中..."
classes_before = ObjectSpace.each_object(Class).to_a
modules_before = ObjectSpace.each_object(Module).to_a.reject { |m| m.is_a?(Class) }
puts "  クラス数: #{classes_before.size}"
puts "  モジュール数: #{modules_before.size}"

# instance_variable_get（安全）
_ = extractor.instance_variable_get(:@tasks)

# tasks メソッド呼び出し（危険）
puts "\n[2] tasks メソッド呼び出し実行..."
tasks_result = extractor.tasks
puts "  取得したタスク: #{tasks_result.inspect}"

# tasks メソッド呼び出し後のクラス一覧を取得
puts "\n[3] tasks メソッド呼び出し後のクラス一覧を取得中..."
classes_after = ObjectSpace.each_object(Class).to_a
modules_after = ObjectSpace.each_object(Module).to_a.reject { |m| m.is_a?(Class) }
puts "  クラス数: #{classes_after.size}"
puts "  モジュール数: #{modules_after.size}"

# 差分を計算
new_classes = classes_after - classes_before
new_modules = modules_after - modules_before

# 結果を表示
puts "\n" + "=" * 80
puts "差分結果"
puts "=" * 80
puts "\n[新しく作成されたクラス] (#{new_classes.size} 個)"
new_classes.first(30).each do |klass|
  puts "  - #{klass.name || '(anonymous)'}"
end
puts "  ... (#{new_classes.size - 30} 個省略)" if new_classes.size > 30

puts "\n[新しく作成されたモジュール] (#{new_modules.size} 個)"
new_modules.first(20).each do |mod|
  puts "  - #{mod.name || '(anonymous)'}"
end
puts "  ... (#{new_modules.size - 20} 個省略)" if new_modules.size > 20

# 名前空間でグルーピング
puts "\n[名前空間別の新クラス集計]"
namespace_counts = new_classes.group_by do |klass|
  name = klass.name
  next "(anonymous)" unless name

  # トップレベル名前空間を取得
  parts = name.split("::")
  parts.size > 1 ? parts[0] : name
end

namespace_counts.sort_by { |_, classes| -classes.size }.first(10).each do |namespace, classes|
  puts "  #{namespace}: #{classes.size} 個"
end

puts "\n実験終了"
