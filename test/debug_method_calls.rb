#!/usr/bin/env ruby
# frozen_string_literal: true

# メソッド呼び出し詳細追跡：extractor.tasks がどのメソッドを経由して実行されるか

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

puts "=" * 80
puts "メソッド呼び出し詳細追跡実験"
puts "=" * 80

# RakeTaskExtractor インスタンス作成
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor)

puts "\n[準備完了] extractor インスタンス作成、accept 呼び出し済み"

# extractor オブジェクトの詳細情報
puts "\n[extractor オブジェクト情報]"
puts "  クラス: #{extractor.class}"
puts "  継承チェーン: #{extractor.class.ancestors.first(10).join(' < ')}"
puts "  tasks メソッドの定義場所: #{extractor.method(:tasks).owner}"
puts "  tasks メソッドのソース: #{extractor.method(:tasks).source_location}"

# tasks メソッドが attr_reader で定義されているか確認
puts "\n[tasks メソッドの性質]"
puts "  respond_to?(:tasks): #{extractor.respond_to?(:tasks)}"
puts "  instance_variable_defined?(:@tasks): #{extractor.instance_variable_defined?(:@tasks)}"
puts "  @tasks の値: #{extractor.instance_variable_get(:@tasks).inspect}"

# Thor::Task や Rake との名前衝突を確認
puts "\n[名前空間の衝突チェック]"
puts "  Thor::Task 存在: #{defined?(Thor::Task) ? 'Yes' : 'No'}"
puts "  Rake::Task 存在: #{defined?(Rake::Task) ? 'Yes' : 'No'}"
puts "  Rake.application 存在: #{defined?(Rake.application) ? 'Yes' : 'No'}"

# メソッド呼び出し前後でのオブジェクト変化を詳細に追跡
puts "\n[オブジェクト変化の詳細追跡]"
before_counts = ObjectSpace.count_objects

# ここで tasks メソッドを呼び出す
puts "\n  tasks メソッド呼び出し中..."
call_depth = 0
call_stack = []

trace = TracePoint.new(:call, :c_call, :return, :c_return) do |tp|
  # tasks メソッド呼び出しに関連するもののみ追跡
  next unless tp.defined_class.to_s =~ /(Rake|Thor|Test)/

  case tp.event
  when :call, :c_call
    call_depth += 1
    if call_depth <= 5 # 深すぎるネストは避ける
      call_stack << "#{tp.defined_class}##{tp.method_id}"
    end
  when :return, :c_return
    call_depth -= 1
  end
end

trace.enable do
  tasks_result = extractor.tasks
  puts "  取得したタスク: #{tasks_result.inspect}"
end

after_counts = ObjectSpace.count_objects

# 変化を表示
puts "\n[オブジェクト変化]"
puts "  TOTAL: #{before_counts[:TOTAL]} → #{after_counts[:TOTAL]} (+#{after_counts[:TOTAL] - before_counts[:TOTAL]})"
puts "  T_OBJECT: #{before_counts[:T_OBJECT]} → #{after_counts[:T_OBJECT]} (+#{after_counts[:T_OBJECT] - before_counts[:T_OBJECT]})"
puts "  T_CLASS: #{before_counts[:T_CLASS]} → #{after_counts[:T_CLASS]} (+#{after_counts[:T_CLASS] - before_counts[:T_CLASS]})"
puts "  T_MODULE: #{before_counts[:T_MODULE]} → #{after_counts[:T_MODULE]} (+#{after_counts[:T_MODULE] - before_counts[:T_MODULE]})"
puts "  T_ARRAY: #{before_counts[:T_ARRAY]} → #{after_counts[:T_ARRAY]} (+#{after_counts[:T_ARRAY] - before_counts[:T_ARRAY]})"

# Rake/Thor 関連の呼び出しがあったか表示
puts "\n[Rake/Thor/Test 関連の呼び出しスタック]"
if call_stack.empty?
  puts "  (呼び出しなし)"
else
  call_stack.uniq.each do |call|
    puts "  - #{call}"
  end
end

puts "\n実験終了"
