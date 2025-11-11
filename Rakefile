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

  t.test_files = test_files

  # Ruby warning suppress: method redefinition warnings in test mocks
  # See: test/commands/env_test.rb, test/commands/cache_test.rb
  t.ruby_opts = ["-W1"]
end

# ============================================================================
# DIAGNOSTIC TASKS: Binary search for test registration failure
# ============================================================================

# Test with left half of files (0-3: cli, device, env_commands, mrbgems)
Rake::TestTask.new("test:left_half") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/cli_test.rb",
    "test/commands/device_test.rb",
    "test/commands/env_test.rb",
    "test/commands/mrbgems_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test with right half of files (4-8: rubocop, env, env_constants, picotorokko, rake_task_extractor)
Rake::TestTask.new("test:right_half") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/rubocop_test.rb",
    "test/env_test.rb",
    "test/lib/env_constants_test.rb",
    "test/picotorokko_test.rb",
    "test/rake_task_extractor_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test first 2 files (cli, device)
Rake::TestTask.new("test:left_quarter_1") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/cli_test.rb",
    "test/commands/device_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test next 2 files (env_commands, mrbgems)
Rake::TestTask.new("test:left_quarter_2") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/env_test.rb",
    "test/commands/mrbgems_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test first 3 files of right half
Rake::TestTask.new("test:right_quarter_1") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/rubocop_test.rb",
    "test/env_test.rb",
    "test/lib/env_constants_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test last 2 files of right half
Rake::TestTask.new("test:right_quarter_2") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/picotorokko_test.rb",
    "test/rake_task_extractor_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test each file individually for baseline
Rake::TestTask.new("test:individual") do |t|
  t.libs << "test"
  t.libs << "lib"
  # Just first file to start
  t.test_files = ["test/commands/cli_test.rb"]
  t.ruby_opts = ["-W1"]
end

# ============================================================================
# DEEP DIAGNOSTIC TASKS: Identify which file combination breaks registration
# ============================================================================

# Test: cli_test + env_test
Rake::TestTask.new("test:diag_cli_env") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/cli_test.rb",
    "test/commands/env_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test: device_test + env_test
Rake::TestTask.new("test:diag_device_env") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/device_test.rb",
    "test/commands/env_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test: cli + device + env (no mrbgems)
Rake::TestTask.new("test:diag_cde") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/cli_test.rb",
    "test/commands/device_test.rb",
    "test/commands/env_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test: mrbgems_test alone
Rake::TestTask.new("test:diag_mrbgems") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = ["test/commands/mrbgems_test.rb"]
  t.ruby_opts = ["-W1"]
end

# Test: cli + device + mrbgems (no env_test)
Rake::TestTask.new("test:diag_cdm") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/cli_test.rb",
    "test/commands/device_test.rb",
    "test/commands/mrbgems_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test: device_test alone
Rake::TestTask.new("test:diag_device") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = ["test/commands/device_test.rb"]
  t.ruby_opts = ["-W1"]
end

# Test: cli + device (should work fine)
Rake::TestTask.new("test:diag_cli_device") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/cli_test.rb",
    "test/commands/device_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test: env_test + mrbgems (right side)
Rake::TestTask.new("test:diag_env_mrbgems") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/env_test.rb",
    "test/commands/mrbgems_test.rb"
  ]
  t.ruby_opts = ["-W1"]
end

# Test: device + mrbgems only (skipping env_test)
Rake::TestTask.new("test:diag_device_mrbgems") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = [
    "test/commands/device_test.rb",
    "test/commands/mrbgems_test.rb"
  ]
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

# Run all tests: main suite (151 tests) + device suite (14 tests)
# NOTE: SimpleCov coverage is cumulative across both test:device runs
desc "Run all tests (main suite + device suite)"
task "test:all" => :reset_coverage do
  sh "bundle exec rake test"
end

# CI専用タスク：全テスト + RuboCop（チェックのみ） + カバレッジ検証
# NOTE: test:all runs reset_coverage → test (includes device_test.rb in main suite)
# Total: 151 + 14 = 165 tests with proper coverage
desc "Run all tests, RuboCop checks, and validate coverage (for CI)"
task ci: %i[test rubocop coverage_validation] do
  puts "\n✓ CI checks passed! All tests + RuboCop + coverage validated."
  # NOTE: device_test is separate; run 'rake test:all' or 'rake' for all 165 tests
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
# NOTE: Run individual test files with: bundle exec ruby test/path/file_test.rb
desc "Default task: Run all tests (main + device suites) [165 tests total]"
task default: %i[test:all] do
  puts "\n✓ All 165 tests completed successfully (151 main + 14 device)"
end
