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
  # Group 2: Environment Setup and Device Command Success
  # ============================================================================
  sub_test_case "Scenario: Device command success with valid environment" do
    test "device env list is available" do
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
  end

  # ============================================================================
  # Group 3: Build Workspace File Operations (PLACEHOLDER)
  # ============================================================================
  sub_test_case "Scenario: Build workspace file operations" do
    test "build workspace structure exists after project creation" do
      # OMITTED: Build workspace tests pending environment setup implementation
      omit "Build workspace tests pending proper env set command pattern"
    end
  end
end
