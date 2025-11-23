# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/picotorokko/commands/new"
require_relative "../../lib/picotorokko/commands/env"
require_relative "../../lib/picotorokko/commands/device"

class ScenarioBuildPreconditionTest < PicotorokkoTestCase
  # Build precondition verification tests
  # Verify that ptrk device build can actually proceed after scenario setup

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  sub_test_case "Scenario: Build precondition verification" do
    test "PROBLEM: env set_environment without env directory causes build to fail" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Simulate env set (only writes to .picoruby-env.yml, doesn't create .ptrk_env/)
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env_name = "20251123_150000"
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Set current environment
          capture_stdout do
            Picotorokko::Commands::Env.start(["current", env_name])
          end

          # PROBLEM: .ptrk_env/{env_name}/ does NOT exist
          env_path = File.join(Picotorokko::Env::ENV_DIR, env_name)
          refute Dir.exist?(env_path), "Expected .ptrk_env/#{env_name}/ to NOT exist (this is the bug)"

          # This means build will fail
          # Attempting build should raise "Environment directory not found"
          device_cmd = Picotorokko::Commands::Device.new
          error = assert_raises(RuntimeError) do
            device_cmd.send(:setup_build_environment_for_device, env_name)
          end
          assert_match(/Environment directory not found/, error.message)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "SOLUTION: create .ptrk_env directory structure for build to succeed" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Set environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env_name = "20251123_160000"
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # SOLUTION: Actually create the .ptrk_env/{env_name}/ directory structure
          env_path = File.join(Picotorokko::Env::ENV_DIR, env_name)
          r2p2_path = File.join(env_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_path)

          # Create minimal R2P2-ESP32 structure for build
          FileUtils.mkdir_p(File.join(r2p2_path, "storage", "home"))
          FileUtils.mkdir_p(File.join(r2p2_path, "mrbgems"))
          File.write(File.join(r2p2_path, "Rakefile"), "# Minimal Rakefile\n")

          # Now .ptrk_env exists
          assert Dir.exist?(env_path)

          # Setup build environment should succeed
          device_cmd = Picotorokko::Commands::Device.new
          capture_stdout do
            device_cmd.send(:setup_build_environment_for_device, env_name)
          end

          # Verify build directory was created
          build_path = Picotorokko::Env.get_build_path(env_name)
          assert Dir.exist?(build_path)
          assert Dir.exist?(File.join(build_path, "R2P2-ESP32"))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Verification: storage/home is copied to build directory" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Add file to storage/home
          File.write("storage/home/app.rb", "puts 'Hello'")

          # Set environment
          env_name = "20251123_170000"
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Create .ptrk_env structure
          env_path = File.join(Picotorokko::Env::ENV_DIR, env_name)
          r2p2_path = File.join(env_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_path)

          # Setup build environment
          device_cmd = Picotorokko::Commands::Device.new
          capture_stdout do
            device_cmd.send(:setup_build_environment_for_device, env_name)
          end

          # Verify storage/home was copied
          build_path = Picotorokko::Env.get_build_path(env_name)
          storage_in_build = File.join(build_path, "R2P2-ESP32", "storage", "home", "app.rb")
          assert File.exist?(storage_in_build), "storage/home/app.rb should be copied to build"
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Verification: mrbgems are copied to build directory" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Set environment
          env_name = "20251123_180000"
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Create .ptrk_env structure
          env_path = File.join(Picotorokko::Env::ENV_DIR, env_name)
          r2p2_path = File.join(env_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_path)

          # Setup build environment
          device_cmd = Picotorokko::Commands::Device.new
          capture_stdout do
            device_cmd.send(:setup_build_environment_for_device, env_name)
          end

          # Verify mrbgems was copied
          build_path = Picotorokko::Env.get_build_path(env_name)
          mrbgems_in_build = File.join(build_path, "R2P2-ESP32", "mrbgems", "app")
          assert Dir.exist?(mrbgems_in_build), "mrbgems/app should be copied to build"
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "KNOWN ISSUE: actual rake execution fails without proper Rakefile" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project
          Dir.chdir("myapp")
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Set environment
          env_name = "20251123_190000"
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Create .ptrk_env structure with minimal Rakefile
          env_path = File.join(Picotorokko::Env::ENV_DIR, env_name)
          r2p2_path = File.join(env_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_path)
          File.write(File.join(r2p2_path, "Rakefile"), "# Minimal Rakefile - no tasks defined\n")

          # Set current env
          capture_stdout do
            Picotorokko::Commands::Env.start(["current", env_name])
          end

          # Setup build will succeed
          device_cmd = Picotorokko::Commands::Device.new
          capture_stdout do
            device_cmd.send(:setup_build_environment_for_device, env_name)
          end

          # But actual rake execution will fail (no build task defined)
          # This documents the known issue mentioned by the user
          build_path = Picotorokko::Env.get_build_path(env_name)
          rakefile_path = File.join(build_path, "R2P2-ESP32", "Rakefile")
          assert File.exist?(rakefile_path), "Rakefile should exist in build directory"

          # NOTE: Actually running `rake build` here would fail because:
          # 1. No 'build' task is defined in the minimal Rakefile
          # 2. Real R2P2-ESP32 Rakefile requires ESP-IDF environment
          # This is expected behavior - ptrk device build delegates to R2P2's rake
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end
end
