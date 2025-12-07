require "test_helper"

class ScenarioM5UnifiedIntegrationTest < PicotorokkoTestCase
  # M5Unified mrbgem integration シナリオテスト
  # Verify M5Unified mrbgem structure and app.rb configuration

  sub_test_case "Scenario: M5Unified mrbgem integration" do
    test "m5unified mrbgem directory exists" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-m5unified"
      assert Dir.exist?(path), "M5Unified mrbgem directory should exist at #{path}"
    end

    test "m5unified mrbgem contains mrbgem.rake" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-m5unified"
      mrbgem_rake = File.join(path, "mrbgem.rake")
      assert File.exist?(mrbgem_rake), "mrbgem.rake should exist"
    end

    test "m5unified mrbgem contains src/m5unified.c" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-m5unified"
      m5unified_c = File.join(path, "src", "m5unified.c")
      assert File.exist?(m5unified_c), "src/m5unified.c should exist"
    end

    test "m5unified mrbgem contains C++ wrapper" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-m5unified"
      wrapper_cpp = File.join(path, "ports", "esp32", "m5unified_wrapper.cpp")
      assert File.exist?(wrapper_cpp), "ports/esp32/m5unified_wrapper.cpp should exist"
    end

    test "m5unified mrbgem contains CMakeLists.txt" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-m5unified"
      cmake = File.join(path, "CMakeLists.txt")
      assert File.exist?(cmake), "CMakeLists.txt should exist"
    end

    test "Mrbgemfile includes M5Unified mrbgem" do
      path = "/Users/bash/src/picotorokko/playground/m5app/Mrbgemfile"
      content = File.read(path)
      assert_match(/mrbgem-picoruby-m5unified/, content)
    end

    test "Mrbgemfile M5Unified comment is present" do
      path = "/Users/bash/src/picotorokko/playground/m5app/Mrbgemfile"
      content = File.read(path)
      assert_match(/M5Unified/, content)
    end

    test "app.rb uses M5Unified API" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      content = File.read(path)

      assert_match(/M5\.begin/, content)
      assert_match(/M5\.update/, content)
      assert_match(/M5\.BtnA\.wasPressed\?/, content)
    end

    test "app.rb has M5Unified comment" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      content = File.read(path)

      assert_match(/M5Unified/, content)
    end

    test "m5unified_wrapper.cpp has button methods" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-m5unified"
      content = File.read(File.join(path, "ports", "esp32", "m5unified_wrapper.cpp"))

      assert_match(/m5unified_btnA_wasPressed/, content)
      assert_match(/m5unified_begin/, content)
      assert_match(/m5unified_update/, content)
    end

    test "m5unified.c has Button method implementations" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-m5unified"
      content = File.read(File.join(path, "src", "m5unified.c"))

      assert_match(/mrbc_m5_btnA_wasPressed/, content)
      assert_match(/mrbc_define_class.*M5/, content)
    end

    test "CMakeLists.txt requires M5Unified component" do
      path = "/Users/bash/src/picotorokko/playground/m5app/mrbgems/mrbgem-picoruby-m5unified"
      content = File.read(File.join(path, "CMakeLists.txt"))

      assert_match(/REQUIRES\s+m5unified/, content)
    end

    test "app.rb Ruby syntax is valid" do
      path = "/Users/bash/src/picotorokko/playground/m5app/storage/home/app.rb"
      output, status = Open3.capture2e("ruby", "-c", path)
      assert status.success?, "app.rb should have valid Ruby syntax. Output: #{output}"
    end
  end
end
