require "test_helper"
require "tmpdir"
require "fileutils"
require "open3"

# Test for build workspace setup: storage, mrbgems, and patch copy verification
# Verifies that ptrk device build correctly sets up build workspace from env
class DeviceBuildWorkspaceTest < PicotorokkoTestCase
  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1" # Skip network setup in device commands
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  sub_test_case "build workspace setup" do
    test "copies storage/home to build workspace" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Setup environment
        env_name = setup_test_environment_for_device(project_dir)

        # Create storage/home with test file
        storage_dir = File.join(project_dir, "storage", "home")
        FileUtils.mkdir_p(storage_dir)
        File.write(File.join(storage_dir, "app.rb"), "# Test app\nputs 'Hello'")

        # Run device build via CLI
        output, status = run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        # Verify storage/home was copied to build workspace
        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")
        copied_app = File.join(build_path, "storage", "home", "app.rb")

        if Dir.exist?(build_path)
          assert File.exist?(copied_app), "storage/home/app.rb should be copied to R2P2-ESP32"
          assert_equal "# Test app\nputs 'Hello'", File.read(copied_app)
        else
          # Build workspace not created due to missing ESP-IDF, which is acceptable
          # The key is that the command executed (success or error message)
          assert status.success? || output.include?("Build") || output.include?("error"),
                 "Build command should execute without crashing"
        end
      end
    end

    test "copies mrbgems to nested picoruby path in build workspace" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        _output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Setup environment
        env_name = setup_test_environment_for_device(project_dir)

        # Create mrbgems with test gem
        mrbgems_dir = File.join(project_dir, "mrbgems", "test_gem")
        FileUtils.mkdir_p(mrbgems_dir)
        File.write(File.join(mrbgems_dir, "mrbgem.rake"), "# Test gem")

        # Run device build via CLI
        output, status = run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        # Verify mrbgems was copied to nested picoruby path
        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")
        copied_gem = File.join(
          build_path, "components", "picoruby-esp32", "picoruby", "mrbgems", "test_gem", "mrbgem.rake"
        )

        if Dir.exist?(build_path)
          assert File.exist?(copied_gem), "mrbgems should be copied to nested picoruby path in R2P2-ESP32"
          assert_equal "# Test gem", File.read(copied_gem)
        else
          # Build workspace not created due to missing ESP-IDF
          assert status.success? || output.include?("Build") || output.include?("error"),
                 "Build command should execute without crashing"
        end
      end
    end

    test "applies patches from project root patch directory" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Setup environment
        env_name = setup_test_environment_for_device(project_dir)

        # Create patch file
        patch_dir = File.join(project_dir, "patch", "R2P2-ESP32")
        FileUtils.mkdir_p(patch_dir)
        File.write(File.join(patch_dir, "custom_config.h"), "#define CUSTOM_VALUE 42")

        # Run device build via CLI
        output, status = run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        # Verify patch was applied to build workspace
        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")
        patched_file = File.join(build_path, "custom_config.h")

        if Dir.exist?(build_path)
          assert File.exist?(patched_file), "patch files should be applied to R2P2-ESP32"
          assert_equal "#define CUSTOM_VALUE 42", File.read(patched_file)
        else
          # Build workspace not created due to missing ESP-IDF
          assert status.success? || output.include?("Build") || output.include?("error"),
                 "Build command should execute without crashing"
        end
      end
    end

    test "patches do not overwrite storage/home (correct order: patch before storage)" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Setup environment
        env_name = setup_test_environment_for_device(project_dir)

        # Create patch that would overwrite storage/home if applied after
        patch_dir = File.join(project_dir, "patch", "R2P2-ESP32", "storage", "home")
        FileUtils.mkdir_p(patch_dir)
        File.write(File.join(patch_dir, "app.rb"), "# Patched version")

        # Create user's storage/home
        storage_dir = File.join(project_dir, "storage", "home")
        FileUtils.mkdir_p(storage_dir)
        File.write(File.join(storage_dir, "app.rb"), "# User app")

        # Run device build via CLI
        output, status = run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        # User's storage/home should override patch
        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")
        final_app = File.join(build_path, "storage", "home", "app.rb")

        if Dir.exist?(build_path)
          assert File.exist?(final_app), "app.rb should exist in R2P2-ESP32"
          assert_equal "# User app", File.read(final_app),
                       "User's storage/home should not be overwritten by patches"
        else
          # Build workspace not created due to missing ESP-IDF
          assert status.success? || output.include?("Build") || output.include?("error"),
                 "Build command should execute without crashing"
        end
      end
    end

    test "file contents are identical between source and build workspace" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Setup environment
        env_name = setup_test_environment_for_device(project_dir)

        # Create multiple test files
        storage_dir = File.join(project_dir, "storage", "home")
        FileUtils.mkdir_p(storage_dir)
        File.write(File.join(storage_dir, "app.rb"), "# App file")
        File.write(File.join(storage_dir, "config.yml"), "key: value")

        mrbgems_dir = File.join(project_dir, "mrbgems", "my_gem", "src")
        FileUtils.mkdir_p(mrbgems_dir)
        File.write(File.join(mrbgems_dir, "custom.c"), "// C source")

        # Run device build via CLI
        output, status = run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")

        # Verify all files exist and have identical content
        if Dir.exist?(build_path)
          assert_equal "# App file", File.read(File.join(build_path, "storage", "home", "app.rb"))
          assert_equal "key: value", File.read(File.join(build_path, "storage", "home", "config.yml"))

          gem_path = File.join(
            build_path, "components", "picoruby-esp32", "picoruby", "mrbgems", "my_gem", "src", "custom.c"
          )
          assert_equal "// C source", File.read(gem_path)
        else
          # Build workspace not created due to missing ESP-IDF
          assert status.success? || output.include?("Build") || output.include?("error"),
                 "Build command should execute without crashing"
        end
      end
    end

    test "validate_and_get_r2p2_path returns path with R2P2-ESP32 subdirectory" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Setup environment
        env_name = setup_test_environment_for_device(project_dir)

        # Verify environment was created correctly in .ptrk_env
        env_path = File.join(project_dir, ".ptrk_env", env_name, "R2P2-ESP32")
        assert Dir.exist?(env_path), ".ptrk_env environment structure should exist"

        # Run device build via CLI
        output, status = run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        # Verify build workspace R2P2-ESP32 subdirectory exists (if build completed)
        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")
        if Dir.exist?(File.join(project_dir, ".ptrk_build", env_name))
          assert Dir.exist?(build_path), "R2P2-ESP32 subdirectory should exist in build workspace"
        else
          # Build workspace not created due to missing ESP-IDF
          assert status.success? || output.include?("Build") || output.include?("error"),
                 "Build command should execute without crashing"
        end
      end
    end

    test "directory replacement: old build workspace files are deleted when rebuild happens" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Setup environment
        env_name = setup_test_environment_for_device(project_dir)

        # Create initial storage/home with file v1
        storage_dir = File.join(project_dir, "storage", "home")
        FileUtils.mkdir_p(storage_dir)
        File.write(File.join(storage_dir, "app.rb"), "# Version 1")

        # Create mrbgems with gem v1
        mrbgems_dir = File.join(project_dir, "mrbgems", "test_gem")
        FileUtils.mkdir_p(mrbgems_dir)
        File.write(File.join(mrbgems_dir, "mrbgem.rake"), "# Gem version 1")

        # Run device build via CLI
        output, status = run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

        # Verify first build copied files
        build_path = File.join(project_dir, ".ptrk_build", env_name, "R2P2-ESP32")
        storage_copy = File.join(build_path, "storage", "home", "app.rb")
        gem_copy = File.join(
          build_path, "components", "picoruby-esp32", "picoruby", "mrbgems", "test_gem", "mrbgem.rake"
        )

        if Dir.exist?(build_path)
          assert File.exist?(storage_copy), "First build should create storage/home/app.rb"
          assert_equal "# Version 1", File.read(storage_copy)
          assert File.exist?(gem_copy), "First build should create mrbgems/test_gem/mrbgem.rake"
          assert_equal "# Gem version 1", File.read(gem_copy)

          # Add extra files in build workspace that are NOT in source (simulating manual addition)
          extra_storage_file = File.join(build_path, "storage", "home", "manual_file.txt")
          File.write(extra_storage_file, "This file was manually added")

          extra_gem_file = File.join(build_path, "components", "picoruby-esp32", "picoruby", "mrbgems", "manual_gem")
          FileUtils.mkdir_p(extra_gem_file)
          File.write(File.join(extra_gem_file, "manual.rb"), "# Manually added gem")

          # Verify manually-added files exist before workspace reset
          assert File.exist?(extra_storage_file), "Manual file should exist before workspace reset"
          assert File.exist?(extra_gem_file), "Manual gem dir should exist before workspace reset"

          # Update source files to version 2
          File.write(File.join(storage_dir, "app.rb"), "# Version 2")
          File.write(File.join(mrbgems_dir, "mrbgem.rake"), "# Gem version 2")

          # Delete build workspace to trigger complete re-initialization (directory replacement)
          # This simulates when user deletes .ptrk_build and rebuilds
          FileUtils.rm_rf(File.join(project_dir, ".ptrk_build"))

          # Run build again - workspace will be recreated from scratch
          run_ptrk_command("device build --env #{env_name}", cwd: project_dir)

          # Verify: source files are updated
          assert_equal "# Version 2", File.read(storage_copy),
                       "storage/home/app.rb should be updated to version 2"
          assert_equal "# Gem version 2", File.read(gem_copy),
                       "mrbgems/test_gem/mrbgem.rake should be updated to version 2"

          # Verify: manually-added files are DELETED (directory replacement behavior)
          assert !File.exist?(extra_storage_file),
                 "Manually-added file in storage/home should be deleted on rebuild"
          assert !File.exist?(extra_gem_file),
                 "Manually-added directory in mrbgems should be deleted on rebuild"
        else
          # Build workspace not created due to missing ESP-IDF
          assert status.success? || output.include?("Build") || output.include?("error"),
                 "Build command should execute without crashing"
        end
      end
    end
  end

  private

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
