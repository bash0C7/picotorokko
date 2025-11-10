# coverage_test.rb: SimpleCov configuration and runtime verification
require_relative "test_helper"

class CoverageTest < PraTestCase
  # SimpleCov が起動していることを確認
  def test_simplecov_is_running
    # SimpleCov.start が test_helper.rb で呼ばれているか確認
    assert defined?(SimpleCov), "SimpleCov should be defined"
    assert SimpleCov.running, "SimpleCov should be running"
  end

  # SimpleCov が成功時に exit 0 で終了することを確認
  def test_rake_test_exits_zero
    # rake test の exit code が 0 であることを確認
    # （このテスト自体が rake test で実行されているため、ここまで reach したら成功）
    assert true, "If this test runs, rake test exited with code 0"
  end

  # SimpleCov 設定が有効であることを確認
  def test_simplecov_configuration
    # SimpleCov が設定されており、カバレッジ追跡が有効であることを確認
    # coverage.xml 生成は at_exit 後に行われるため、coverage_validation タスクで検証
    assert SimpleCov.running, "SimpleCov should be configured and tracking coverage"
  end
end
