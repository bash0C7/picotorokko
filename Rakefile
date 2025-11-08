# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

# 開発時のデフォルトタスク：クイックにテストのみ実行
task default: %i[test]

# CI専用タスク：テスト + コード品質チェック
desc "Run tests with coverage checks and RuboCop linting (for CI)"
task ci: %i[test rubocop]

# 品質チェック統合タスク
desc "Run all quality checks (tests and linting)"
task quality: %i[test rubocop]

# 開発者向け：pre-commitフック用タスク
desc "Pre-commit checks: RuboCop linting and tests"
task "pre-commit": %i[rubocop test] do
  puts "\n✓ Pre-commit checks passed! Ready to commit."
end
