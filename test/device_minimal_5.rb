# Step 5: 実際のテストメソッドの中身を追加
require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsDeviceTest < PraTestCase
  include SystemCommandMocking

  sub_test_case "device flash command" do
    test "raises error when environment not found" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          assert_raise(RuntimeError) do
            capture_stdout do
              Picotorokko::Commands::Device.start(['flash', '--env', 'nonexistent-env'])
            end
          end
        end
      end
    end
  end
end
