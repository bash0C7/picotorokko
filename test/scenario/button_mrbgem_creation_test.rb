require "test_helper"

class ScenarioButtonMrbgemCreationTest < PicotorokkoTestCase
  # Button mrbgem creation シナリオテスト
  # Verify button mrbgem structure is correctly created

  sub_test_case "Scenario: Button mrbgem structure" do
    test "button mrbgem directory exists" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-button"
      assert Dir.exist?(path), "button mrbgem directory should exist at #{path}"
    end

    test "button mrbgem contains mrbgem.rake" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-button"
      mrbgem_rake = File.join(path, "mrbgem.rake")
      assert File.exist?(mrbgem_rake), "mrbgem.rake should exist"
    end

    test "button mrbgem contains src/button.c" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-button"
      button_c = File.join(path, "src", "button.c")
      assert File.exist?(button_c), "src/button.c should exist"
    end

    test "mrbgem.rake has correct specification" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-button"
      content = File.read(File.join(path, "mrbgem.rake"))

      assert_match(/mrbgem-picoruby-button/, content)
      assert_match(/MIT/, content)
      assert_match(/ESP32/, content)
    end

    test "button.c has Button class initialization" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-button"
      content = File.read(File.join(path, "src", "button.c"))

      assert_match(/mrbc_mrbgem_picoruby_button_gem_init/, content)
      assert_match(/mrbc_define_class.*Button/, content)
    end

    test "button.c has required methods" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-button"
      content = File.read(File.join(path, "src", "button.c"))

      assert_match(/c_button_init/, content)
      assert_match(/c_button_update/, content)
      assert_match(/c_button_was_pressed/, content)
      assert_match(/c_button_is_pressed/, content)
    end

    test "button.c uses GPIO39 for ATOM Matrix" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-button"
      content = File.read(File.join(path, "src", "button.c"))

      assert_match(/GPIO_NUM_39/, content)
    end

    test "button.c includes required headers" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-button"
      content = File.read(File.join(path, "src", "button.c"))

      assert_match(/#include <mrubyc\.h>/, content)
      assert_match(%r{#include "driver/gpio\.h"}, content)
      assert_match(%r{#include "freertos/FreeRTOS\.h"}, content)
    end

    test "button.c has debouncing logic" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-button"
      content = File.read(File.join(path, "src", "button.c"))

      assert_match(/DEBOUNCE_MS/, content)
      assert_match(/was_pressed_flag/, content)
    end
  end
end
