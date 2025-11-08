# カバレッジ測定の開始（他のrequireより前に実行）
require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/vendor/"
  add_filter "/lib/pra/templates/"  # ユーザープロジェクト向けテンプレートは除外
  enable_coverage :branch
  # NOTE: 段階的にカバレッジ要件を引き上げ（Phase 3.2 にて 60% 達成）
  # 最終的には line: 80, branch: 50 に設定（Phase 3.4）
  minimum_coverage line: 60, branch: 30 if ENV["CI"]
end

# Codecov v4対応: Cobertura XML形式で出力
require "simplecov-cobertura"
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pra"

require "test-unit"
