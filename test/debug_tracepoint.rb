#!/usr/bin/env ruby
# frozen_string_literal: true

# TracePoint 追跡実験：extractor.tasks メソッド呼び出し時に何がロードされるか追跡

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

puts "=" * 80
puts "TracePoint 追跡実験開始"
puts "=" * 80

# RakeTaskExtractor インスタンス作成
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor)

puts "\n[準備完了] extractor インスタンス作成、accept 呼び出し済み"

# TracePoint を設定（require, class, module 定義を追跡）
loaded_files = []
defined_classes = []
defined_modules = []

trace = TracePoint.new(:class, :call, :c_call) do |tp|
  case tp.event
  when :class
    if tp.self.is_a?(Class)
      defined_classes << tp.self.name if tp.self.name
    elsif tp.self.is_a?(Module)
      defined_modules << tp.self.name if tp.self.name
    end
  when :call, :c_call
    # require や load の呼び出しを追跡
    if tp.method_id == :require || tp.method_id == :load
      # Kernel.require の呼び出しを記録
      loaded_files << tp.binding.eval("path") rescue nil
    end
  end
end

puts "\n[TracePoint 有効化] tasks メソッド呼び出し開始..."
trace.enable do
  # tasks メソッド呼び出し（危険）
  tasks_result = extractor.tasks
  puts "  取得したタスク: #{tasks_result.inspect}"
end

puts "\n[TracePoint 無効化] 追跡終了"

# 結果を表示
puts "\n" + "=" * 80
puts "追跡結果"
puts "=" * 80
puts "\n[ロードされたファイル] (#{loaded_files.compact.size} 個)"
loaded_files.compact.uniq.each do |file|
  puts "  - #{file}"
end

puts "\n[定義されたクラス] (#{defined_classes.compact.uniq.size} 個)"
defined_classes.compact.uniq.first(20).each do |klass|
  puts "  - #{klass}"
end
puts "  ... (#{defined_classes.compact.uniq.size - 20} 個省略)" if defined_classes.compact.uniq.size > 20

puts "\n[定義されたモジュール] (#{defined_modules.compact.uniq.size} 個)"
defined_modules.compact.uniq.first(20).each do |mod|
  puts "  - #{mod}"
end
puts "  ... (#{defined_modules.compact.uniq.size - 20} 個省略)" if defined_modules.compact.uniq.size > 20

puts "\n実験終了"
