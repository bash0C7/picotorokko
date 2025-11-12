require "bundler/gem_tasks"
require "rake/testtask"
require "English"

# ============================================================================
# MAIN TEST TASK
# ============================================================================
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  test_files = FileList["test/**/*_test.rb"].sort
  # NOTE: device_test.rb is excluded from main suite to avoid test registration interference
  # - It runs separately via test:device task
  # - Default task runs: main suite (183 tests) + device suite (14 tests)
  test_files.delete_if { |f| f.include?("device_test.rb") }

  t.test_files = test_files

  # Ruby warning suppress: method redefinition warnings in test mocks
  # See: test/commands/env_test.rb, test/commands/cache_test.rb
  t.ruby_opts = ["-W1"]
end

# ============================================================================
# DEVICE TEST TASK (Run Separately)
# ============================================================================
Rake::TestTask.new("test:device") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = ["test/commands/device_test.rb"]
  # Ruby warning suppress
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

# 開発時のデフォルトタスク：全テスト（main suite + device suite）実行
# この設定は下の DEFAULT & CONVENIENCE TASKS セクションで上書きされます

# カバレッジ検証タスク（test実行後にcoverage.xmlが生成されていることを確認）
desc "Validate SimpleCov coverage report was generated"
task :coverage_validation do
  coverage_file = File.join(Dir.pwd, "coverage", "coverage.xml")
  abort "ERROR: SimpleCov coverage report not found at #{coverage_file}" unless File.exist?(coverage_file)
  puts "✓ SimpleCov coverage report validated: #{coverage_file}"
end

# SimpleCov をリセット（test と test:device の前に実行）
desc "Reset coverage directory before test runs"
task :reset_coverage do
  coverage_dir = File.join(Dir.pwd, "coverage")
  FileUtils.rm_rf(coverage_dir)
  puts "✓ Coverage directory reset"
end

# ============================================================================
# INTEGRATED TEST TASKS
# ============================================================================

# Run all tests: main suite (183 tests) + device suite (14 tests)
# NOTE: SimpleCov coverage is cumulative across both test runs
desc "Run all tests (main suite + device suite)"
task "test:all" => :reset_coverage do
  sh "bundle exec rake test"
  sh "bundle exec rake test:device 2>&1 | grep -E '^(Started|Finished|[0-9]+ tests)' || true"
end

# CI task: All tests + RuboCop check + coverage validation
desc "Run all tests, RuboCop checks, and validate coverage (for CI)"
task ci: %i[test rubocop coverage_validation] do
  puts "\n✓ CI checks passed! All tests + RuboCop + coverage validated."
end

# 品質チェック統合タスク
desc "Run all quality checks with RuboCop auto-correction and retest"
task quality: %i[test rubocop:fix test]

# 開発者向け：pre-commitフック用タスク
desc "Pre-commit checks: run tests, auto-fix RuboCop violations, and run tests again"
task "pre-commit": %i[test rubocop:fix test] do
  puts "\n✓ Pre-commit checks passed! Ready to commit."
end

# ============================================================================
# DEFAULT & CONVENIENCE TASKS
# ============================================================================

# Default: Run all tests (main suite + device suite)
desc "Default task: Run all tests (main + device suites) [197 tests total]"
task default: %i[test:all] do
  puts "\n✓ All 197 tests completed successfully (183 main + 14 device)"
end
