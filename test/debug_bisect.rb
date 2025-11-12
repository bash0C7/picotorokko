#!/usr/bin/env ruby
# frozen_string_literal: true

# 二分探索：debug_objectspace.rb のどの部分が問題を再現させるか

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"

# [削除] Test::Unit のロード前の記録を削除
# before_test_unit = { ... }

# Test::Unit をロード
require "test-unit"

# [削除] Test::Unit ロード後の記録を削除
# after_test_unit = { ... }

# [削除] at_exit hook 登録状況の確認を削除

# RakeTaskExtractor インスタンス作成
source = "task :build do; end"
result = Prism.parse(source)
extractor = Picotorokko::Commands::RakeTaskExtractor.new
result.value.accept(extractor)

# [削除] RakeTaskExtractor 作成後の記録を削除

# instance_variable_get 呼び出し
tasks_via_ivar = extractor.instance_variable_get(:@tasks)

# tasks メソッド呼び出し前
before = ObjectSpace.count_objects

# tasks メソッド呼び出し
tasks_via_method = extractor.tasks

# tasks メソッド呼び出し後
after = ObjectSpace.count_objects

# 結果表示
puts "tasks メソッド呼び出し前後の ObjectSpace 変化:"
puts "  TOTAL: #{before[:TOTAL]} → #{after[:TOTAL]} (+#{after[:TOTAL] - before[:TOTAL]})"
puts "  T_CLASS: #{before[:T_CLASS]} → #{after[:T_CLASS]} (+#{after[:T_CLASS] - before[:T_CLASS]})"
