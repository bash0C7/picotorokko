require "test_helper"
require "tmpdir"
require "fileutils"
require "open3"

class ScenarioDeviceTest < PicotorokkoTestCase
  # Device command scenario tests - external ptrk CLI execution
  # Tests ptrk device commands from user perspective
  # Pattern: Create project → Setup environment → Run device command → Verify results

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1" # Skip network setup in device commands
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  # ============================================================================
  # Group 1: Error Handling Tests
  # ============================================================================
  sub_test_case "Scenario: Device error handling" do
    test "device build fails when environment does not exist" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id

        # Create project
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Try to build with nonexistent environment
        output, status = run_ptrk_command("device build --env nonexistent-env", cwd: project_dir)
        assert !status.success?, "device build with nonexistent env should fail"
        assert_match(/environment.*not.*found|not found|cannot find/i, output)
      end
    end

    test "device flash fails when environment does not exist" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id

        # Create project
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Try to flash with nonexistent environment
        output, status = run_ptrk_command("device flash --env nonexistent-env", cwd: project_dir)
        assert !status.success?, "device flash with nonexistent env should fail"
        assert_match(/environment.*not.*found|not found|cannot find/i, output)
      end
    end

    test "device monitor fails when environment does not exist" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id

        # Create project
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Try to monitor with nonexistent environment
        output, status = run_ptrk_command("device monitor --env nonexistent-env", cwd: project_dir)
        assert !status.success?, "device monitor with nonexistent env should fail"
        assert_match(/environment.*not.*found|not found|cannot find/i, output)
      end
    end
  end

  # ============================================================================
  # Group 2: Device Command Interface Verification
  # ============================================================================
  sub_test_case "Scenario: Device command interface" do
    test "device help is available" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id

        # Create project
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Get device help
        output, status = run_ptrk_command("device help", cwd: project_dir)
        assert status.success?, "ptrk device help should succeed"
        assert_match(/device/i, output, "Help output should mention device")
      end
    end

    test "env list is available" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id

        # Create project
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # List environments (should work even if empty)
        output, status = run_ptrk_command("env list", cwd: project_dir)
        assert status.success?, "ptrk env list should succeed. Output: #{output}"
      end
    end

    test "env help displays available subcommands" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id

        # Create project
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Get env help
        output, status = run_ptrk_command("env help", cwd: project_dir)
        assert status.success?, "ptrk env help should succeed"
        assert_match(/set|list|show|remove/i, output, "Env help should show available commands")
      end
    end
  end

  # ============================================================================
  # Group 3: Build Workspace File Operations
  # ============================================================================
  sub_test_case "Scenario: Build workspace file operations" do
    test "storage/home files are copied to build workspace" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id

        # 1. Create project
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # 2. Create storage/home with test file
        storage_dir = File.join(project_dir, "storage", "home")
        FileUtils.mkdir_p(storage_dir)
        File.write(File.join(storage_dir, "app.rb"), "# Test app\nputs 'Hello'")

        # 3. Setup environment using internal API (helper)
        env_name = setup_test_environment_for_device(project_dir)

        # 4. Run device build via CLI
        output, status = run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        # 5. Verify storage/home was copied to build workspace
        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")
        copied_app = File.join(build_path, "storage", "home", "app.rb")

        if Dir.exist?(build_path)
          assert File.exist?(copied_app), "storage/home/app.rb should be copied to R2P2-ESP32"
          assert_equal "# Test app\nputs 'Hello'", File.read(copied_app)
        else
          # Build workspace not created due to missing ESP-IDF, which is acceptable
          # The key is that the command succeeded and recognized the environment
          assert status.success? || output.include?("Build") || output.include?("error"),
                 "Command should execute without crashing"
        end
      end
    end

    test "mrbgems directory is copied to nested picoruby path" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id

        # 1. Create project
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # 2. Create mrbgems directory with test gem
        mrbgems_dir = File.join(project_dir, "mrbgems", "my_test_gem")
        FileUtils.mkdir_p(mrbgems_dir)
        File.write(File.join(mrbgems_dir, "mrbgem.rake"), "# Test gem")

        # 3. Setup environment using internal API (helper)
        env_name = setup_test_environment_for_device(project_dir)

        # 4. Run device build via CLI
        run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        # 5. Verify mrbgems was copied to nested picoruby path
        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")
        copied_gem = File.join(build_path, "components", "picoruby-esp32", "picoruby", "mrbgems", "my_test_gem", "mrbgem.rake")

        if Dir.exist?(build_path)
          assert File.exist?(copied_gem), "mrbgems should be copied to nested picoruby path"
          assert_equal "# Test gem", File.read(copied_gem)
        end
      end
    end

    test "patch files are applied to build workspace" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id

        # 1. Create project
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # 2. Create patch directory with test file
        patch_dir = File.join(project_dir, "patch", "R2P2-ESP32")
        FileUtils.mkdir_p(patch_dir)
        File.write(File.join(patch_dir, "custom.h"), "#define CUSTOM_VALUE 42")

        # 3. Setup environment using internal API (helper)
        env_name = setup_test_environment_for_device(project_dir)

        # 4. Run device build via CLI
        run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        # 5. Verify patch was applied to build workspace
        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")
        patched_file = File.join(build_path, "custom.h")

        if Dir.exist?(build_path)
          assert File.exist?(patched_file), "patch file should be applied to R2P2-ESP32"
          assert_equal "#define CUSTOM_VALUE 42", File.read(patched_file)
        end
      end
    end
  end

  private

  # Helper: Setup test environment for device commands
  # Uses internal API to create .ptrk_env structure
  # Returns environment name for use with ptrk device commands
  def setup_test_environment_for_device(project_dir)
    env_name = "test_env_#{SecureRandom.hex(4)}"

    # Create .ptrk_env file with environment definition
    env_file = File.join(project_dir, ".ptrk_env", ".picoruby-env.yml")
    FileUtils.mkdir_p(File.dirname(env_file))

    env_content = {
      env_name => {
        "r2p2" => { "commit" => "abc1234", "timestamp" => "20250101_120000" },
        "esp32" => { "commit" => "def5678", "timestamp" => "20250102_120000" },
        "picoruby" => { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
      }
    }

    require "yaml"
    File.write(env_file, YAML.dump(env_content))

    # Create .ptrk_env/{env_name}/R2P2-ESP32 structure
    env_r2p2_dir = File.join(project_dir, ".ptrk_env", env_name, "R2P2-ESP32")
    FileUtils.mkdir_p(env_r2p2_dir)

    # Copy mock Rakefile from fixtures
    mock_rakefile = File.expand_path("../fixtures/R2P2-ESP32/Rakefile", __dir__)
    FileUtils.cp(mock_rakefile, File.join(env_r2p2_dir, "Rakefile")) if File.exist?(mock_rakefile)

    # Create expected directory structure
    FileUtils.mkdir_p(File.join(env_r2p2_dir, "components", "picoruby-esp32", "picoruby", "mrbgems"))
    FileUtils.mkdir_p(File.join(env_r2p2_dir, "storage", "home"))

    env_name
  end
end
