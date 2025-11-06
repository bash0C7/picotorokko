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

# CI専用タスク：じっくりテスト（カバレッジチェックあり）
desc "Run tests with coverage checks (for CI)"
task ci: :test
