# カバレッジ測定の開始（他のrequireより前に実行）
require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/vendor/"
  add_filter "/lib/pra/templates/" # ユーザープロジェクト向けテンプレートは除外
  enable_coverage :branch
  # NOTE: 段階的にカバレッジ要件を引き上げ
  # Phase 3.2: 60% 達成
  # Phase 4.1: line 75%, branch 55% (現実的な基準値)
  # 将来目標: line 85%, branch 65% (TODO.mdで低優先度タスク化)
  # TDDサイクルで常にカバレッジチェック（CI環境限定なし）
  minimum_coverage line: 75, branch: 55
end

# Codecov v4対応: Cobertura XML形式で出力
require "simplecov-cobertura"
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

# NOTE: SystemExit cleanup code removed - device_test.rb is excluded from test suite
# If device_test.rb is re-enabled in the future, SystemExit handling must be implemented
# See TODO.md "Fix device_test.rb Thor command argument handling" for details

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pra"

require "test-unit"
require "tmpdir"

# テスト用 ptrk_user_root を一時ディレクトリで設定
# これにより、テスト実行中に gem root に汚染がないようにする
ENV["PTRK_USER_ROOT"] = Dir.mktmpdir("ptrk_test_")

# テスト用基底クラス：PROJECT_ROOT のリセットを処理
class PraTestCase < Test::Unit::TestCase
  # setup: 各テスト開始時に PROJECT_ROOT をリセット
  def setup
    super
    # PROJECT_ROOT を現在の作業ディレクトリに基づいてリセット
    begin
      Pra::Env.__send__(:remove_const, :PROJECT_ROOT) if Pra::Env.const_defined?(:PROJECT_ROOT)
      Pra::Env.const_set(:PROJECT_ROOT, Dir.pwd)
    rescue StandardError
      # Ignore any errors during setup
    end

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

      # PROJECT_ROOT をリセット（現在の Dir.pwd を基準に）
      begin
        Pra::Env.__send__(:remove_const, :PROJECT_ROOT) if Pra::Env.const_defined?(:PROJECT_ROOT)
        Pra::Env.const_set(:PROJECT_ROOT, Dir.pwd)
      rescue StandardError
        # Ignore
      end
    end
  end

  # teardown: テスト終了後にテスト作成物をクリーンアップ
  def teardown
    super
    begin
      Pra::Env.__send__(:remove_const, :PROJECT_ROOT) if Pra::Env.const_defined?(:PROJECT_ROOT)
      Pra::Env.const_set(:PROJECT_ROOT, Dir.pwd) if Dir.pwd
    rescue StandardError
      # Silently ignore teardown errors
    end

    # テスト中に作成された一時ファイル・ディレクトリを確実にクリーンアップ
    # （.gitignore されているものだけを削除するため、リポジトリ管理物は損壊しない）
    begin
      dirs_to_cleanup = [
        Pra::Env::BUILD_DIR,   # build/
        Pra::Env::PATCH_DIR,   # patch/
        Pra::Env::CACHE_DIR    # .cache/
      ]

      files_to_cleanup = [
        Pra::Env::ENV_FILE     # .picoruby-env.yml
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
  def verify_git_status_clean!(phase)
    # Use git diff to check only unstaged changes (working tree modifications)
    result = `git diff --name-only 2>&1`
    return if result.empty?

    message = "Git working directory has unstaged changes #{phase}. Modified files:\n#{result}"
    raise StandardError, message
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
    system('git init', out: File::NULL) || raise('git init failed')
    system('git config user.email "test@example.com"')
    system('git config user.name "Test User"')
    system('git config commit.gpgsign false') # Disable commit signing for tests
    File.write('test.txt', 'test')
    system('git add .') || raise('git add failed')
    system('git commit -m "test"', out: File::NULL) || raise('git commit failed')
  end
end
