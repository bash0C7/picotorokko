# Step 3: require test_helper + require device + ダミーテストクラス
require_relative "test_helper"
require "picotorokko/commands/device"

class DummyTest < PraTestCase
  def test_dummy
    assert_true(true)
  end
end
