#!/usr/bin/env ruby
# frozen_string_literal: true

# 何が初期化されるか ObjectSpace で追跡

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

# RakeTaskExtractor インスタンス作成
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor)

# respond_to? 呼び出し前のクラス一覧
puts "[1] respond_to? 呼び出し前のクラス一覧を取得"
classes_before_respond_to = ObjectSpace.each_object(Class).to_a
puts "  クラス数: #{classes_before_respond_to.size}"

# respond_to? 呼び出し
_ = Test::Unit::AutoRunner.respond_to?(:need_run?)

puts "\n[2] respond_to? 呼び出し後のクラス一覧を取得"
classes_after_respond_to = ObjectSpace.each_object(Class).to_a
puts "  クラス数: #{classes_after_respond_to.size}"

# tasks 呼び出し前のクラス一覧
puts "\n[3] tasks 呼び出し前"
classes_before_tasks = ObjectSpace.each_object(Class).to_a
puts "  クラス数: #{classes_before_tasks.size}"

# tasks 呼び出し
_ = extractor.tasks

puts "\n[4] tasks 呼び出し後"
classes_after_tasks = ObjectSpace.each_object(Class).to_a
puts "  クラス数: #{classes_after_tasks.size}"

# 差分を計算
new_classes_by_respond_to = classes_after_respond_to - classes_before_respond_to
new_classes_by_tasks = classes_after_tasks - classes_before_tasks

# 結果を表示
puts "\n" + "=" * 80
puts "差分結果"
puts "=" * 80
puts "\n[respond_to? で作成されたクラス] (#{new_classes_by_respond_to.size} 個)"
new_classes_by_respond_to.first(20).each do |klass|
  puts "  - #{klass.name || '(anonymous)'}"
end
puts "  ... (#{new_classes_by_respond_to.size - 20} 個省略)" if new_classes_by_respond_to.size > 20

puts "\n[tasks で作成されたクラス] (#{new_classes_by_tasks.size} 個)"
new_classes_by_tasks.first(30).each do |klass|
  puts "  - #{klass.name || '(anonymous)'}"
end
puts "  ... (#{new_classes_by_tasks.size - 30} 個省略)" if new_classes_by_tasks.size > 30

# 名前空間でグルーピング
puts "\n[tasks で作成されたクラスの名前空間別集計]"
namespace_counts = new_classes_by_tasks.group_by do |klass|
  name = klass.name
  next "(anonymous)" unless name

  # トップレベル名前空間を取得
  parts = name.split("::")
  parts.size > 1 ? parts[0] : name
end

namespace_counts.sort_by { |_, classes| -classes.size }.first(15).each do |namespace, classes|
  puts "  #{namespace}: #{classes.size} 個"
end
