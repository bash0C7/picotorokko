#!/usr/bin/env ruby
# frozen_string_literal: true

# puts 文の影響を確認

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "prism"
require "picotorokko/commands/device"
require "test-unit"

# [実験 1] puts 文なし
puts "[実験 1] puts 文なし"
source1 = "task :build do; end"
result1 = Prism.parse(source1)
extractor1 = Picotorokko::Commands::RakeTaskExtractor.new
result1.value.accept(extractor1)

before1 = ObjectSpace.count_objects
_ = extractor1.tasks
after1 = ObjectSpace.count_objects
puts "  TOTAL 変化: +#{after1[:TOTAL] - before1[:TOTAL]}, T_CLASS 変化: +#{after1[:T_CLASS] - before1[:T_CLASS]}"

# [実験 2] puts 文あり（tasks 呼び出しの前）
puts "\n[実験 2] puts 文あり（tasks 呼び出しの前）"
source2 = "task :build do; end"
result2 = Prism.parse(source2)
extractor2 = Picotorokko::Commands::RakeTaskExtractor.new
result2.value.accept(extractor2)

before2 = ObjectSpace.count_objects
puts "  tasks 呼び出し前..."
_ = extractor2.tasks
after2 = ObjectSpace.count_objects
puts "  TOTAL 変化: +#{after2[:TOTAL] - before2[:TOTAL]}, T_CLASS 変化: +#{after2[:T_CLASS] - before2[:T_CLASS]}"

# [実験 3] puts 文 2 つあり（tasks 呼び出しの前後）
puts "\n[実験 3] puts 文 2 つあり（tasks 呼び出しの前後）"
source3 = "task :build do; end"
result3 = Prism.parse(source3)
extractor3 = Picotorokko::Commands::RakeTaskExtractor.new
result3.value.accept(extractor3)

before3 = ObjectSpace.count_objects
puts "  tasks 呼び出し前..."
_ = extractor3.tasks
puts "  tasks 呼び出し後..."
after3 = ObjectSpace.count_objects
puts "  TOTAL 変化: +#{after3[:TOTAL] - before3[:TOTAL]}, T_CLASS 変化: +#{after3[:T_CLASS] - before3[:T_CLASS]}"
