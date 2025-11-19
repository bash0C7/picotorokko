# カバレッジ測定の開始（他のrequireより前に実行）
require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/vendor/"
  add_filter "/lib/picotorokko/templates/" # ユーザープロジェクト向けテンプレートは除外
  # NOTE: 段階的にカバレッジ要件を引き上げ
  # Phase 3.2: 60% 達成
  # Phase 4.1: line 75%, branch 55% (実装)
  # Phase 5.0: line 85%, branch 65% (現在の基準値)
  # 開発環境: ライン単位のカバレッジのみ計測（高速化）
  # CI環境: ブランチカバレッジも計測
  enable_coverage :branch if ENV["CI"]

  # Minimum coverage validation only in CI environments
  # Development: coverage is measured but validation is skipped
  # CI: coverage validation enforced (line 85%, branch 65%)
  if ENV["CI"]
    minimum_coverage line: 85
    minimum_coverage branch: 65
  end
end

# Codecov v4対応: Cobertura XML形式で出力（CI環境のみ）
# 開発環境ではHTMLFormatter使用で高速化
require "simplecov-cobertura"
SimpleCov.formatter = if ENV["CI"]
                        SimpleCov::Formatter::CoberturaFormatter
                      else
                        SimpleCov::Formatter::HTMLFormatter
                      end

# NOTE: SystemExit cleanup code removed - device_test.rb is excluded from test suite
# If device_test.rb is re-enabled in the future, SystemExit handling must be implemented
# See TODO.md [TODO-INFRASTRUCTURE-DEVICE-TEST] for details

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "picotorokko"

require "test-unit"
require "tmpdir"
require "securerandom"

# Aliases for backward compatibility
Ptrk = Picotorokko unless defined?(Ptrk)

# テスト用 ptrk_user_root を一時ディレクトリで設定
# これにより、テスト実行中に gem root に汚染がないようにする
ENV["PTRK_USER_ROOT"] = Dir.mktmpdir("ptrk_test_")

# Base test class for all picotorokko tests
class PicotorokkoTestCase < Test::Unit::TestCase
  # setup: 各テスト開始時に初期化
  def setup
    super
    # NOTE: PROJECT_ROOT は動的メソッド（Picotorokko::Env.project_root）に変更されたため、
    # 定数操作は不要になった。Dir.pwd の変更が自動的に反映される。

    # CRITICAL FIX: Reset cached project root at test start
    # This ensures each test starts with the current directory as the project root
    Picotorokko::Env.reset_cached_root!

    # Verify git status is clean before test starts
    verify_git_status_clean!("before test")
  end

  # Dir.chdir(tmpdir) 後に PROJECT_ROOT をリセットするヘルパー
  def with_fresh_project_root
    original_dir = Dir.pwd

    # 事前状態チェック: build/ が存在していれば前のテストのクリーンアップ失敗を示す
    build_dir = File.join(original_dir, "build")
    raise "ERROR: build/ directory exists before test. Previous test teardown incomplete." if Dir.exist?(build_dir)

    begin
      yield
    ensure
      Dir.chdir(original_dir)

      # テスト実行中に作成された build/ を必ずクリーンアップ
      FileUtils.rm_rf(build_dir)

      # CRITICAL FIX: Reset cached project root when returning from chdir
      # This ensures patch_dir, cache_dir point back to the original directory
      Picotorokko::Env.reset_cached_root!
    end
  end

  # teardown: テスト終了後にテスト作成物をクリーンアップ
  def teardown
    super

    # テスト中に作成された一時ファイル・ディレクトリを確実にクリーンアップ
    # （.gitignore されているものだけを削除するため、リポジトリ管理物は損壊しない）
    begin
      dirs_to_cleanup = [
        File.join(Picotorokko::Env.project_root, "build"),    # build/
        Picotorokko::Env.patch_dir,                           # ptrk_env/patch/
        Picotorokko::Env.cache_dir                            # ptrk_env/.cache/
      ]

      files_to_cleanup = [
        Picotorokko::Env.env_file                             # ptrk_env/.picoruby-env.yml
      ]

      dirs_to_cleanup.each do |dir|
        FileUtils.rm_rf(dir)
      end

      files_to_cleanup.each do |file|
        FileUtils.rm_f(file)
      end
    rescue StandardError
      # Silently ignore cleanup errors
    end

    # Verify git status is clean after test completes
    verify_git_status_clean!("after test")
  end

  # NOTE: after_test cleanup code removed - device_test.rb is excluded from test suite
  # If device_test.rb is re-enabled in the future, implement per-test SystemExit isolation
  private

  # Helper: Verify git status is clean (no modifications to tracked files)
  # NOTE: Staging area changes (added files, staged changes) are allowed
  # This only checks for UNSTAGED changes (working tree modifications)
  # WORKAROUND: Temporarily disabled again to verify const_missing implementation
  # Previous attempt to re-enable with dynamic methods did not resolve test registration failure
  # TODO: Investigate why const_missing doesn't prevent git diff subprocess interference
  def verify_git_status_clean!(phase)
    # DISABLED: git diff subprocess still interferes with test-unit registration even after
    # refactoring constants to dynamic methods. Needs further investigation.
    # result = `git diff --name-only 2>&1`
    # return if result.empty?
    # message = "Git working directory has unstaged changes #{phase}. Modified files:\n#{result}"
    # raise StandardError, message
  end

  # Helper: Verify gem root is not polluted with build artifacts
  def verify_gem_root_clean!
    gem_root = Dir.pwd
    pollution_dirs = %w[build ptrk_env .cache patch]
    polluted = pollution_dirs.select { |dir| File.exist?(File.join(gem_root, dir)) }

    return if polluted.empty?

    message = "Gem root is polluted with: #{polluted.join(", ")}"
    raise StandardError, message
  end

  # Helper: Setup minimal git repository for testing
  # Creates a clean git repo with one commit in the current directory
  # Usage: Dir.mktmpdir { |dir| Dir.chdir(dir) { setup_test_git_repo; ... } }
  def setup_test_git_repo
    system("git init", out: File::NULL) || raise("git init failed")
    system('git config user.email "test@example.com"')
    system('git config user.name "Test User"')
    system("git config commit.gpgsign false") # Disable commit signing for tests
    File.write("test.txt", "test")
    system("git add .") || raise("git add failed")
    system('git commit -m "test"', out: File::NULL) || raise("git commit failed")
  end
end

# Refinement-based system command mocking for CI compatibility
# Shared by env_test.rb and device_test.rb
module SystemCommandMocking
  # Store original Kernel#system before refinement
  ORIGINAL_SYSTEM = Kernel.instance_method(:system)

  # Command handler methods (extracted to reduce system() complexity)
  def self.process_git_clone_command(cmd, mock_context)
    mock_context[:call_count][:clone] += 1
    return false if mock_context[:fail_clone]

    # Create dummy git repository at destination path
    if cmd =~ /git clone.* (\S+)\s*$/
      dest_path = ::Regexp.last_match(1).gsub(/['"]/, "")
      FileUtils.mkdir_p(dest_path)
      FileUtils.mkdir_p(File.join(dest_path, ".git"))
    end
    true
  end

  def self.process_git_checkout_command(mock_context)
    mock_context[:call_count][:checkout] += 1
    !mock_context[:fail_checkout]
  end

  def self.process_git_submodule_command(mock_context)
    mock_context[:call_count][:submodule] += 1
    !mock_context[:fail_submodule]
  end

  def self.process_rake_command(mock_context)
    mock_context[:call_count][:rake] += 1
    !mock_context[:fail_rake]
  end

  # Scoped Kernel#system override using Refinement
  # This approach is CI-compatible (no global state pollution)
  module SystemRefinement
    refine Kernel do
      def system(*args)
        # Check if mock context is active in thread-local storage
        mock_context = Thread.current[:system_mock_context]
        return SystemCommandMocking::ORIGINAL_SYSTEM.bind_call(self, *args) unless mock_context

        cmd = args.join(" ")
        mock_context[:commands_executed] << cmd

        # Dispatch to appropriate command handler
        return SystemCommandMocking.process_git_clone_command(cmd, mock_context) if cmd.include?("git clone")
        return SystemCommandMocking.process_git_checkout_command(mock_context) if cmd.include?("git checkout")
        return SystemCommandMocking.process_git_submodule_command(mock_context) if cmd.include?("git submodule update")
        return SystemCommandMocking.process_rake_command(mock_context) if cmd.include?("rake")

        # Fallback to original system() for other commands
        SystemCommandMocking::ORIGINAL_SYSTEM.bind_call(self, *args)
      end
    end
  end

  # Helper method to set up system command mocking with Refinement
  # Usage: with_system_mocking(fail_clone: true) { |mock| ... }
  # Note: Refinement is already applied at class level via 'using' declaration
  def with_system_mocking(fail_clone: false, fail_checkout: false, fail_submodule: false, fail_rake: false)
    mock_context = {
      call_count: { clone: 0, checkout: 0, submodule: 0, rake: 0 },
      commands_executed: [],
      fail_clone: fail_clone,
      fail_checkout: fail_checkout,
      fail_submodule: fail_submodule,
      fail_rake: fail_rake
    }

    Thread.current[:system_mock_context] = mock_context

    begin
      yield(mock_context)
    ensure
      Thread.current[:system_mock_context] = nil
    end
  end

  # Helper method to mock Picotorokko::Env.execute_with_esp_env for device tests
  # Usage: with_esp_env_mocking { |mock| ... }
  # This mocks execute_with_esp_env to track commands instead of executing them
  def with_esp_env_mocking(fail_command: false)
    mock_context = {
      commands_executed: [],
      fail_command: fail_command
    }

    Thread.current[:esp_env_mock_context] = mock_context

    original_method = Picotorokko::Env.method(:execute_with_esp_env)
    Picotorokko::Env.define_singleton_method(:execute_with_esp_env) do |command, working_dir = nil|
      ctx = Thread.current[:esp_env_mock_context]
      return original_method.call(command, working_dir) unless ctx

      ctx[:commands_executed] << command
      raise "Command failed: #{command}" if ctx[:fail_command]
    end

    begin
      yield(mock_context)
    ensure
      Thread.current[:esp_env_mock_context] = nil
      Picotorokko::Env.define_singleton_method(:execute_with_esp_env, original_method)
    end
  end
end
