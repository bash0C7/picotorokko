require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

# Test for build workspace setup: storage, mrbgems, and patch copy verification
# Verifies that ptrk device build correctly sets up build workspace from env
class DeviceBuildWorkspaceTest < PicotorokkoTestCase
  include SystemCommandMocking

  def teardown
    # Clean up test artifacts from project root
    %w[mrbgems patch].each do |dir|
      path = File.join(Dir.pwd, dir)
      FileUtils.rm_rf(path)
    end
    # Clean up storage/home test files (but not the directory itself)
    storage_home = File.join(Dir.pwd, "storage", "home")
    if Dir.exist?(storage_home)
      Dir.glob(File.join(storage_home, "*")).each do |f|
        FileUtils.rm_rf(f) unless File.basename(f) == "app.rb" && File.read(f).include?("# storage home")
      end
    end
    super
  end

  sub_test_case "build workspace setup" do
    test "copies storage/home to build workspace" do
      Dir.mktmpdir do |tmpdir|
        with_fresh_project_root do
          Dir.chdir(tmpdir)

          # Setup environment with storage/home
          setup_complete_test_environment("test-env")

          # Create storage/home with test file
          storage_dir = File.join(Picotorokko::Env.project_root, "storage", "home")
          FileUtils.mkdir_p(storage_dir)
          File.write(File.join(storage_dir, "app.rb"), "# Test app\nputs 'Hello'")

          with_esp_env_mocking do |_mock|
            capture_stdout do
              Picotorokko::Commands::Device.start(["build", "--env", "test-env"])
            end
          end

          # Verify storage/home was copied to build workspace
          build_path = Picotorokko::Env.get_build_path("test-env")
          copied_app = File.join(build_path, "R2P2-ESP32", "storage", "home", "app.rb")

          assert File.exist?(copied_app), "storage/home/app.rb should be copied to R2P2-ESP32"
          assert_equal "# Test app\nputs 'Hello'", File.read(copied_app)
        end
      end
    end

    test "copies mrbgems to nested picoruby path in build workspace" do
      Dir.mktmpdir do |tmpdir|
        with_fresh_project_root do
          Dir.chdir(tmpdir)

          # Setup environment
          setup_complete_test_environment("test-env")

          # Create mrbgems with test gem
          mrbgems_dir = File.join(Picotorokko::Env.project_root, "mrbgems", "test_gem")
          FileUtils.mkdir_p(mrbgems_dir)
          File.write(File.join(mrbgems_dir, "mrbgem.rake"), "# Test gem")

          with_esp_env_mocking do |_mock|
            capture_stdout do
              Picotorokko::Commands::Device.start(["build", "--env", "test-env"])
            end
          end

          # Verify mrbgems was copied to nested picoruby path
          build_path = Picotorokko::Env.get_build_path("test-env")
          copied_gem = File.join(
            build_path, "R2P2-ESP32", "components", "picoruby-esp32", "picoruby", "mrbgems", "test_gem", "mrbgem.rake"
          )

          assert File.exist?(copied_gem), "mrbgems should be copied to nested picoruby path in R2P2-ESP32"
          assert_equal "# Test gem", File.read(copied_gem)
        end
      end
    end

    test "applies patches from project root patch directory" do
      Dir.mktmpdir do |tmpdir|
        with_fresh_project_root do
          Dir.chdir(tmpdir)

          # Setup environment
          setup_complete_test_environment("test-env")

          # Create patch file
          patch_dir = File.join(Picotorokko::Env.project_root, "patch", "R2P2-ESP32")
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, "custom_config.h"), "#define CUSTOM_VALUE 42")

          with_esp_env_mocking do |_mock|
            capture_stdout do
              Picotorokko::Commands::Device.start(["build", "--env", "test-env"])
            end
          end

          # Verify patch was applied to build workspace
          build_path = Picotorokko::Env.get_build_path("test-env")
          patched_file = File.join(build_path, "R2P2-ESP32", "custom_config.h")

          assert File.exist?(patched_file), "patch files should be applied to R2P2-ESP32"
          assert_equal "#define CUSTOM_VALUE 42", File.read(patched_file)
        end
      end
    end

    test "patches do not overwrite storage/home (correct order: patch before storage)" do
      Dir.mktmpdir do |tmpdir|
        with_fresh_project_root do
          Dir.chdir(tmpdir)

          # Setup environment
          setup_complete_test_environment("test-env")

          # Create patch that would overwrite storage/home if applied after
          patch_dir = File.join(Picotorokko::Env.project_root, "patch", "R2P2-ESP32", "storage", "home")
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, "app.rb"), "# Patched version")

          # Create user's storage/home
          storage_dir = File.join(Picotorokko::Env.project_root, "storage", "home")
          FileUtils.mkdir_p(storage_dir)
          File.write(File.join(storage_dir, "app.rb"), "# User app")

          with_esp_env_mocking do |_mock|
            capture_stdout do
              Picotorokko::Commands::Device.start(["build", "--env", "test-env"])
            end
          end

          # User's storage/home should override patch
          build_path = Picotorokko::Env.get_build_path("test-env")
          final_app = File.join(build_path, "R2P2-ESP32", "storage", "home", "app.rb")

          assert File.exist?(final_app), "app.rb should exist in R2P2-ESP32"
          assert_equal "# User app", File.read(final_app),
                       "User's storage/home should not be overwritten by patches"
        end
      end
    end

    test "file contents are identical between source and build workspace" do
      Dir.mktmpdir do |tmpdir|
        with_fresh_project_root do
          Dir.chdir(tmpdir)

          # Setup environment
          setup_complete_test_environment("test-env")

          # Create multiple test files
          storage_dir = File.join(Picotorokko::Env.project_root, "storage", "home")
          FileUtils.mkdir_p(storage_dir)
          File.write(File.join(storage_dir, "app.rb"), "# App file")
          File.write(File.join(storage_dir, "config.yml"), "key: value")

          mrbgems_dir = File.join(Picotorokko::Env.project_root, "mrbgems", "my_gem", "src")
          FileUtils.mkdir_p(mrbgems_dir)
          File.write(File.join(mrbgems_dir, "custom.c"), "// C source")

          with_esp_env_mocking do |_mock|
            capture_stdout do
              Picotorokko::Commands::Device.start(["build", "--env", "test-env"])
            end
          end

          build_path = Picotorokko::Env.get_build_path("test-env")
          r2p2_path = File.join(build_path, "R2P2-ESP32")

          # Verify all files exist and have identical content
          assert_equal "# App file", File.read(File.join(r2p2_path, "storage", "home", "app.rb"))
          assert_equal "key: value", File.read(File.join(r2p2_path, "storage", "home", "config.yml"))

          gem_path = File.join(
            r2p2_path, "components", "picoruby-esp32", "picoruby", "mrbgems", "my_gem", "src", "custom.c"
          )
          assert_equal "// C source", File.read(gem_path)
        end
      end
    end

    test "validate_and_get_r2p2_path returns path with R2P2-ESP32 subdirectory" do
      Dir.mktmpdir do |tmpdir|
        with_fresh_project_root do
          Dir.chdir(tmpdir)

          # Setup environment
          setup_complete_test_environment("test-env")

          with_esp_env_mocking do |_mock|
            capture_stdout do
              Picotorokko::Commands::Device.start(["build", "--env", "test-env"])
            end
          end

          # Get expected path with R2P2-ESP32 subdirectory
          build_path = Picotorokko::Env.get_build_path("test-env")
          expected_r2p2_path = File.join(build_path, "R2P2-ESP32")

          # Call validate_and_get_r2p2_path via device command
          device_cmd = Picotorokko::Commands::Device.new
          actual_r2p2_path = device_cmd.send(:validate_and_get_r2p2_path, "test-env")

          # Should return path including R2P2-ESP32 subdirectory
          assert_equal expected_r2p2_path, actual_r2p2_path,
                       "validate_and_get_r2p2_path should return path with R2P2-ESP32 subdirectory"
        end
      end
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def setup_complete_test_environment(env_name)
    r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
    esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
    picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

    Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

    # Create .ptrk_env/{env_name}/R2P2-ESP32/ structure
    # This simulates what clone_env_repository creates
    env_path = File.join(Picotorokko::Env::ENV_DIR, env_name)
    r2p2_path = File.join(env_path, "R2P2-ESP32")
    FileUtils.mkdir_p(env_path)

    # Create directory structure that matches actual R2P2-ESP32 repo structure
    FileUtils.mkdir_p(File.join(r2p2_path, "components", "picoruby-esp32", "picoruby", "mrbgems"))
    FileUtils.mkdir_p(File.join(r2p2_path, "storage", "home"))

    # Copy mock Rakefile
    mock_rakefile = File.join(File.expand_path("../..", __dir__), "fixtures", "R2P2-ESP32", "Rakefile")
    FileUtils.cp(mock_rakefile, File.join(r2p2_path, "Rakefile"))

    env_name
  end
end
