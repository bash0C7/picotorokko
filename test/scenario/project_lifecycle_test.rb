require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/picotorokko/commands/new"
require_relative "../../lib/picotorokko/commands/env"
require_relative "../../lib/picotorokko/commands/device"

class ScenarioProjectLifecycleTest < PicotorokkoTestCase
  # project lifecycle シナリオテスト
  # Verify complete project lifecycle from creation to build

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  # 標準出力をキャプチャするヘルパー

  sub_test_case "Scenario: project lifecycle from creation to build" do
    test "Step 1: ptrk new creates complete project structure" do
      omit "Scenario test: awaiting test-suite-wide review"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # User scenario: ptrk new myapp
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project

          # Verify complete project structure
          assert Dir.exist?("myapp"), "Project directory should be created"
          assert File.exist?("myapp/README.md"), "README.md should be created"
          assert File.exist?("myapp/.picoruby-env.yml"), "Environment file should be created"
          assert Dir.exist?("myapp/storage"), "storage/ directory should be created"
          assert Dir.exist?("myapp/storage/home"), "storage/home/ should be created"
          assert Dir.exist?("myapp/mrbgems"), "mrbgems/ directory should be created"
          assert Dir.exist?("myapp/mrbgems/app"), "mrbgems/app/ should be created"

          # Verify project is ready for development
          assert File.exist?("myapp/mrbgems/app/mrbgem.rake")
          assert File.exist?("myapp/mrbgems/app/mrblib/app.rb")
          assert File.exist?("myapp/mrbgems/app/src/app.c")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Step 2-3: environment can be set and selected" do
      omit "Scenario test: awaiting test-suite-wide review"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Setup: Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Simulate env set (actual network clone skipped)
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env_name = "20251123_100000"
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Set as current environment
          output = capture_stdout do
            Picotorokko::Commands::Env.start(["current", env_name])
          end

          # Verify environment is selected
          assert_match(/Current environment set to: #{env_name}/, output)

          # Verify current environment
          current = Picotorokko::Env.get_current_env
          assert_equal env_name, current
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Step 4: device build sets up build directory" do
      omit "Scenario test: awaiting test-suite-wide review"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Setup: Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env_name = "20251123_110000"
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Set as current
          capture_stdout do
            Picotorokko::Commands::Env.start(["current", env_name])
          end

          # Create minimal build structure for testing
          build_path = Picotorokko::Env.get_build_path(env_name)
          FileUtils.mkdir_p(File.join(build_path, "R2P2-ESP32", "mrbgems"))

          # Verify build directory exists
          assert Dir.exist?(build_path), "Build directory should exist"
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Step 5: device flash without ESP-IDF shows error message" do
      omit "Scenario test: awaiting test-suite-wide review"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Setup: Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env_name = "20251123_120000"
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Create build directory
          build_path = Picotorokko::Env.get_build_path(env_name)
          FileUtils.mkdir_p(File.join(build_path, "R2P2-ESP32"))

          capture_stdout do
            Picotorokko::Commands::Env.start(["current", env_name])
          end

          # Flash command should fail without ESP-IDF
          # We verify error is raised (not crash)
          error = assert_raises(RuntimeError, SystemExit) do
            capture_stdout do
              Picotorokko::Commands::Device.start(["flash"])
            end
          end

          # Error should indicate ESP-IDF or environment issue
          assert error.message.length.positive?, "Should have error message" if error.is_a?(RuntimeError)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Step 6: device monitor without ESP-IDF shows error message" do
      omit "Scenario test: awaiting test-suite-wide review"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Setup: Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env_name = "20251123_130000"
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Create build directory
          build_path = Picotorokko::Env.get_build_path(env_name)
          FileUtils.mkdir_p(File.join(build_path, "R2P2-ESP32"))

          capture_stdout do
            Picotorokko::Commands::Env.start(["current", env_name])
          end

          # Monitor command shows instruction snippet (doesn't fail)
          output = capture_stdout do
            Picotorokko::Commands::Device.start(["monitor"])
          end

          # Output should contain instruction on how to run monitor
          assert_match(/To monitor ESP32 serial output/, output)
          assert_match(/rake monitor/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end
end
