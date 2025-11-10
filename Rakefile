require "bundler/gem_tasks"
require "rake/testtask"
require "English"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  test_files = FileList["test/**/*_test.rb"]
  # device_test.rb included - investigating test count discrepancy

  t.test_files = test_files

  # Ruby warning suppress: method redefinition warnings in test mocks
  # See: test/commands/env_test.rb, test/commands/cache_test.rb
  t.ruby_opts = ["-W1"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new do |task|
  # CI用：チェックのみ（自動修正なし）
  task.options = []
end

# 開発者向け：RuboCop自動修正タスク
desc "Run RuboCop with auto-correction"
task "rubocop:fix" do
  system("bundle exec rubocop --auto-correct-all")
  exit $CHILD_STATUS.exitstatus unless $CHILD_STATUS.success?
end

# 開発時のデフォルトタスク：クイックにテストのみ実行
task default: %i[test]

# カバレッジ検証タスク（test実行後にcoverage.xmlが生成されていることを確認）
desc "Validate SimpleCov coverage report was generated"
task :coverage_validation do
  coverage_file = File.join(Dir.pwd, "coverage", "coverage.xml")
  abort "ERROR: SimpleCov coverage report not found at #{coverage_file}" unless File.exist?(coverage_file)
  puts "✓ SimpleCov coverage report validated: #{coverage_file}"
end

# CI専用タスク：テスト + RuboCop（チェックのみ） + カバレッジ検証
desc "Run tests, RuboCop checks, and validate coverage (for CI)"
task ci: %i[test rubocop coverage_validation]

# 品質チェック統合タスク
desc "Run all quality checks with RuboCop auto-correction and retest"
task quality: %i[test rubocop:fix test]

# 開発者向け：pre-commitフック用タスク
desc "Pre-commit checks: run tests, auto-fix RuboCop violations, and run tests again"
task "pre-commit": %i[test rubocop:fix test] do
  puts "\n✓ Pre-commit checks passed! Ready to commit."
end
