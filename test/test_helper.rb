# カバレッジ測定の開始（他のrequireより前に実行）
require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/vendor/"
  add_filter "/lib/pra/templates/" # ユーザープロジェクト向けテンプレートは除外
  enable_coverage :branch
  # NOTE: 段階的にカバレッジ要件を引き上げ
  # Phase 3.2: 60% 達成
  # Phase 4: line 85%, branch 60% 目標設定
  minimum_coverage line: 85, branch: 60 if ENV["CI"]
end

# Codecov v4対応: Cobertura XML形式で出力
require "simplecov-cobertura"
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pra"

require "test-unit"

# テスト用基底クラス：PROJECT_ROOT のリセットを処理
class PraTestCase < Test::Unit::TestCase
  # setup: 各テスト開始時に PROJECT_ROOT をリセット
  def setup
    super
    # PROJECT_ROOT を現在の作業ディレクトリに基づいてリセット
    begin
      Pra::Env.const_set(:PROJECT_ROOT, Dir.pwd)
    rescue NameError
      # 定数がまだ定義されていない場合は無視
    end
  end

  # Dir.chdir(tmpdir) 後に PROJECT_ROOT をリセットするヘルパー
  def with_fresh_project_root
    original_dir = Dir.pwd
    begin
      yield
    ensure
      Dir.chdir(original_dir)
      # PROJECT_ROOT をリセット（現在の Dir.pwd を基準に）
      begin
        Pra::Env.const_set(:PROJECT_ROOT, Dir.pwd)
      rescue NameError
        # Ignore
      end
    end
  end

  # teardown: テスト終了後に PROJECT_ROOT を確実にリセット
  def teardown
    super
    begin
      Pra::Env.const_set(:PROJECT_ROOT, Dir.pwd) if Dir.pwd
    rescue StandardError
      # Silently ignore teardown errors
    end
  end
end
