# Step 2: require + クラス定義
require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsDeviceTest < PraTestCase
  include SystemCommandMocking
end
