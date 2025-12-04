require "test_helper"

class ScenarioButtonAppTest < PicotorokkoTestCase
  # Button app.rb implementation シナリオテスト
  # Verify app.rb has correct button demo logic

  sub_test_case "Scenario: Button app.rb implementation" do
    test "app.rb file exists" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      assert File.exist?(path), "app.rb should exist at #{path}"
    end

    test "app.rb has Button.init call" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      content = File.read(path)

      assert_match(/Button\.init/, content)
    end

    test "app.rb has main loop" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      content = File.read(path)

      assert_match(/loop\s+do/, content)
    end

    test "app.rb calls Button.update" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      content = File.read(path)

      assert_match(/Button\.update/, content)
    end

    test "app.rb checks Button.was_pressed?" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      content = File.read(path)

      assert_match(/Button\.was_pressed\?/, content)
    end

    test "app.rb outputs 'push' on button press" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      content = File.read(path)

      assert_match(/puts ["']push["']/, content)
    end

    test "app.rb has sleep in loop" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      content = File.read(path)

      assert_match(/sleep\s+0\.1/, content)
    end

    test "app.rb has boot message" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      content = File.read(path)

      assert_match(/puts.*Button/, content)
    end

    test "app.rb Ruby syntax is valid" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      # This checks if the file has valid Ruby syntax
      # If there's a syntax error, ruby will exit with non-zero status
      output, status = Open3.capture2e("ruby", "-c", path)
      assert status.success?, "app.rb should have valid Ruby syntax. Output: #{output}"
    end
  end
end
