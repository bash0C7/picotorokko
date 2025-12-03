require "bundler/gem_tasks"
require "rake/testtask"
require "English"

# ============================================================================
# TEST TASK STRUCTURE: Unit, Integration, Scenario
# ============================================================================
# NOTE: Test reorganization to separate concerns:
# - test:unit      : Fast unit tests with mocked dependencies (runs individually for feedback)
# - test:integration: Slower integration tests with real network operations
# - test:scenario  : Main workflow scenario tests
# - test           : All tests except device (main suite)
#
# For cumulative coverage (CI), use: rake ci or rake test:all_internal

# Unit tests (fast, mocked network operations) - individual task for rapid feedback
Rake::TestTask.new("test:unit") do |t|
  t.libs << "test"
  t.libs << "lib"
  test_files = FileList["test/unit/**/*_test.rb"].sort
  t.test_files = test_files
  t.ruby_opts = ["-W1"]
end

# Scenario tests (main workflow verification) - individual task
Rake::TestTask.new("test:scenario") do |t|
  t.libs << "test"
  t.libs << "lib"
  test_files = FileList["test/scenario/**/*_test.rb"].sort
  t.test_files = test_files
  t.ruby_opts = ["-W1"]
end

# Integration tests (slower, real network operations) - individual task
Rake::TestTask.new("test:integration") do |t|
  t.libs << "test"
  t.libs << "lib"
  test_files = FileList["test/integration/**/*_test.rb"].sort
  t.test_files = test_files
  t.ruby_opts = ["-W1"]
end

# Main test task (all tests except scenario and device)
# NOTE: Scenario tests are slow and run in CI only (see task :test:all below)
# - test/unit/ (fast, mocked) ~1.3s
# - test/integration/ (real network/git operations) ~30s
# - test/scenario/ (user workflows, time-consuming) - CI only
desc "Run fast tests: unit → integration (scenario tests in CI only)"
task test: [:reset_coverage] do
  puts "Running fast tests (unit → integration, scenario in CI only)..."
  sh "bundle exec rake test:unit"
  sh "bundle exec rake test:integration"
  puts "\n✓ Fast tests passed! (~31s)"
  puts "  To run scenario tests: bundle exec rake test:scenario"
  puts "  To run all tests: bundle exec rake test:all"
  puts "  To run full CI suite: bundle exec rake ci"
end

# All tests task (unit + integration + scenario)
# NOTE: Run locally before pushing to verify full test suite passes
desc "Run all tests including scenario (recommended before push)"
task "test:all" => [:reset_coverage] do
  puts "Running all tests including scenario (unit → integration → scenario)..."
  sh "bundle exec rake test:unit"
  sh "bundle exec rake test:integration"
  sh "bundle exec rake test:scenario"
  puts "\n✓ All tests passed!"
  puts "  Full CI suite (with RuboCop + coverage): bundle exec rake ci"
end

# ============================================================================
# INTERNAL DEVICE TEST TASK (Run Separately due to Thor + test-unit conflict)
# ============================================================================
# NOTE: This task is internal and not exposed as a public task
# It is run as part of the default task and CI flow
Rake::TestTask.new("test:device_internal") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = ["test/scenario/commands/device_test.rb"]
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

# ============================================================================
# TYPE SYSTEM TASKS (Priority 1: rbs-inline + Steep)
# ============================================================================

namespace :rbs do
  desc "Generate RBS files from rbs-inline annotations"
  task :generate do
    puts "📝 Generating .rbs files from rbs-inline annotations..."
    sh "bundle exec rbs-inline --output sig lib"
    puts "✓ .rbs files generated in sig/"
  end
end

desc "Run type check with Steep"
task :steep do
  puts "🔍 Running Steep type checker..."
  sh "bundle exec steep check"
  puts "✓ Type check passed!"
end

# ============================================================================
# DOCUMENTATION TASKS (Priority 2: RBS Documentation Generation)
# ============================================================================

namespace :doc do
  desc "Verify RBS documentation files are generated and ready"
  task generate: :rbs do
    puts ""
    puts "✓ RBS documentation files ready in sig/generated/"
    puts ""
    puts "📚 Documentation Generation Summary:"
    puts "  Phase 2: RubyDoc.info (automatic on gem publish)"
    puts "  Phase 3: Local RBS validation via rbs-inline"
    puts ""
    puts "  Generated:"
    puts "  - RBS files: sig/generated/*.rbs"
    puts "  - Type checking: bundle exec steep check"
    puts ""
    puts "  Publishing:"
    puts "  - RubyDoc.info auto-generates docs from RBS files"
    puts "  - URL: https://rubydoc.info/gems/picotorokko/"
    puts ""
    puts "  Development:"
    puts "  - Edit rbs-inline annotations in lib/**/*.rb"
    puts "  - Run: bundle exec rake rbs:generate"
    puts "  - Verify: bundle exec steep check"
  end
end

# 開発時のデフォルトタスク：全テスト（main suite + device suite）実行
# この設定は下の DEFAULT & CONVENIENCE TASKS セクションで上書きされます

# カバレッジ検証タスク（test実行後にcoverage.xmlが生成されていることを確認）
desc "Validate SimpleCov coverage report was generated"
task :coverage_validation do
  # Check for HTML report (primary format)
  coverage_file = File.join(Dir.pwd, "coverage", "index.html")
  unless File.exist?(coverage_file)
    # Fallback to JSON format
    coverage_file = File.join(Dir.pwd, "coverage", ".resultset.json")
  end
  abort "ERROR: SimpleCov coverage report not found" unless File.exist?(coverage_file)
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
# INTERNAL: Run all tests with cumulative coverage
# ============================================================================

# Run all test types in sequence: unit → integration → scenario → other + device
# SimpleCov accumulates coverage across all runs for accurate total coverage
desc "Run all tests with cumulative coverage: unit → integration → scenario → device"
Rake::TestTask.new("test:all_internal" => :reset_coverage) do |t|
  t.libs << "test"
  t.libs << "lib"
  test_files = FileList["test/**/*_test.rb"].sort
  # Exclude device_test.rb from main suite (test registration interference - runs separately)
  test_files.delete_if { |f| f.include?("device_test.rb") }
  # Order: unit → integration → scenario → other (for logical test flow)
  unit_tests = test_files.select { |f| f.include?("test/unit/") }
  integration_tests = test_files.select { |f| f.include?("test/integration/") }
  scenario_tests = test_files.select { |f| f.include?("test/scenario/") }
  other_tests = test_files - unit_tests - integration_tests - scenario_tests

  t.test_files = unit_tests + integration_tests + scenario_tests + other_tests
  t.ruby_opts = ["-W1"]
end

# ============================================================================
# PUBLIC TASKS: CI and Development
# ============================================================================

# CI task: All tests (unit + integration + scenario + device) + RuboCop + coverage
# Runs test:all_internal (which has unit/integration/scenario) then device tests
desc "Run CI: all tests + RuboCop + coverage validation"
task ci: ["test:all_internal", :rubocop, :coverage_validation] do
  # Run device tests after main tests (coverage accumulates)
  sh "bundle exec rake test:device_internal"
  puts "\n✓ CI passed! All tests + RuboCop + coverage validated."
end

# Development task: RuboCop auto-fix, run unit tests (fast feedback)
desc "Development: RuboCop auto-fix, run unit tests (fast feedback, ~5s)"
task dev: [:reset_coverage] do
  sh "bundle exec rubocop --auto-correct-all"
  sh "bundle exec rake test:unit"
  puts "\n✓ Development checks passed! RuboCop fixed, unit tests passed."
  puts "\nTip: Run 'rake ci' before pushing to verify all tests pass in CI"
end

# ============================================================================
# DEFAULT TASK
# ============================================================================

# Default: Run unit tests only (fast feedback for development)
# Note: Coverage validation is skipped - full coverage is only checked in CI
# Scenario tests are CI-only to keep local development fast
desc "Default task: Run unit tests (fast feedback, ~1.3s)"
task default: [:reset_coverage] do
  sh "bundle exec rake test:unit"
  puts "\n✓ Unit tests completed successfully! (~1.3s)"
  puts "\nTest options:"
  puts "  - rake               : Unit tests (fast feedback, ~1.3s) ← you are here"
  puts "  - rake test:unit     : Unit tests only (same as above, ~1.3s)"
  puts "  - rake test:integration : Integration tests (real git ops, ~30s)"
  puts "  - rake test          : Fast tests (unit → integration, ~31s)"
  puts "  - rake test:all      : All tests (unit → integration → scenario, ~35s)"
  puts "  - rake test:scenario : Scenario tests (main workflows, ~0.8s)"
  puts "  - rake test:device_internal : Device command tests (~5s)"
  puts "  - rake ci            : Full CI suite: all tests + RuboCop + coverage (~65s)"
  puts "  - rake dev           : Dev mode (RuboCop auto-fix + unit tests, ~5s)"
  puts "\nBefore pushing, run: rake test:all && rake ci"
end
