require "test_helper"

class ScenarioButtonMrbgemfileTest < PicotorokkoTestCase
  # Button Mrbgemfile configuration シナリオテスト
  # Verify button mrbgem is correctly configured in Mrbgemfile

  sub_test_case "Scenario: Button mrbgem Mrbgemfile configuration" do
    test "Mrbgemfile exists" do
      path = "/Users/bash/src/picotorokko/playground/m5app/Mrbgemfile"
      assert File.exist?(path), "Mrbgemfile should exist"
    end

    test "Mrbgemfile includes button mrbgem" do
      path = "/Users/bash/src/picotorokko/playground/m5app/Mrbgemfile"
      content = File.read(path)

      assert_match(/mrbgem-picoruby-button/, content)
    end

    test "Mrbgemfile button gem path is correct" do
      path = "/Users/bash/src/picotorokko/playground/m5app/Mrbgemfile"
      content = File.read(path)

      assert_match(%r{conf\.gem "mrbgems/mrbgem-picoruby-button"}, content)
    end

    test "Mrbgemfile has button gem comment" do
      path = "/Users/bash/src/picotorokko/playground/m5app/Mrbgemfile"
      content = File.read(path)

      assert_match(/GPIO button support/, content)
    end

    test "Mrbgemfile still includes app gem" do
      path = "/Users/bash/src/picotorokko/playground/m5app/Mrbgemfile"
      content = File.read(path)

      assert_match(%r{conf\.gem "mrbgems/app"}, content)
    end

    test "Mrbgemfile has mruby-print core gem" do
      path = "/Users/bash/src/picotorokko/playground/m5app/Mrbgemfile"
      content = File.read(path)

      assert_match(/mruby-print/, content)
    end

    test "button mrbgem is listed before app mrbgem" do
      path = "/Users/bash/src/picotorokko/playground/m5app/Mrbgemfile"
      content = File.read(path)

      button_index = content.index("mrbgem-picoruby-button")
      app_index = content.index('conf.gem "mrbgems/app"')

      assert button_index < app_index, "button gem should come before app gem"
    end
  end
end
