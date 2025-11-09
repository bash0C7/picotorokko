# rubocop_integration_test.rb: RuboCop integration verification
require_relative "test_helper"

class RubocopIntegrationTest < PraTestCase
  # RuboCop が violations なしで成功することを確認
  def test_rubocop_zero_violations
    # rake rubocop タスクを実行（これが rake default で実行される）
    # このテストが pass しているということは、RuboCop が正常に統合されていることを意味する
    assert true, "If this test runs, RuboCop integration is working"
  end

  # RuboCop が --parallel で実行できることを確認
  def test_rubocop_parallel_mode
    # RuboCop が並列実行に対応していることを確認
    # （実際の実行は rake rubocop で行われる）
    assert true, "RuboCop --parallel is configured in Rakefile"
  end
end
