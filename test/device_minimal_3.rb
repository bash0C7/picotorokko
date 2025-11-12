# Step 3: require + クラス定義 + 1つのテストメソッド
require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsDeviceTest < PraTestCase
  include SystemCommandMocking

  def test_dummy
    assert_true(true)
  end
end
