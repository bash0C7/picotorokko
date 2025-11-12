# Step 4: sub_test_case を追加
require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsDeviceTest < PraTestCase
  include SystemCommandMocking

  sub_test_case "device flash command" do
    test "dummy test" do
      assert_true(true)
    end
  end
end
