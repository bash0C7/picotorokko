# Step 2: require test_helper + ダミーテストクラス
require_relative "test_helper"

class DummyTest < PraTestCase
  def test_dummy
    assert_true(true)
  end
end
