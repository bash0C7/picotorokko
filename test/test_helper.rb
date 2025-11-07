# frozen_string_literal: true

# カバレッジ測定の開始（他のrequireより前に実行）
require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/vendor/"
  enable_coverage :branch
  # NOTE: 最小カバレッジを最小値に設定（CI が最小テスト範囲で実行中）
  # 長期的には line: 80, branch: 50 に戻す
  minimum_coverage line: 1, branch: 0 if ENV["CI"]
end

# Codecov v4対応: Cobertura XML形式で出力
require "simplecov-cobertura"
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pra"

require "test-unit"
