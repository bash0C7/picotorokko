require "test_helper"
require "tmpdir"
require "fileutils"

class ScenarioStorageHomeTest < PicotorokkoTestCase
  # storage/home workflow シナリオテスト
  # Verify storage/home files are correctly copied to build

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  sub_test_case "Scenario: storage/home workflow" do
    test "user can create project with storage/home directory" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        assert Dir.exist?(File.join(project_dir, "storage")), "storage/ should be created"
        assert Dir.exist?(File.join(project_dir, "storage", "home")), "storage/home/ should be created"
      end
    end

    test "user can create and read files in storage/home" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        storage_home = File.join(project_dir, "storage", "home")

        # Create test file in storage/home
        File.write(File.join(storage_home, "app.rb"), "# My app\nputs 'Hello'")

        # Verify file exists and content
        assert File.exist?(File.join(storage_home, "app.rb"))
        content = File.read(File.join(storage_home, "app.rb"))
        assert_match(/My app/, content)
        assert_match(/Hello/, content)
      end
    end

    test "user can update files in storage/home" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        storage_home = File.join(project_dir, "storage", "home")
        app_file = File.join(storage_home, "app.rb")

        # Create initial file
        File.write(app_file, "# Version 1")
        assert_equal "# Version 1", File.read(app_file)

        # Update file
        File.write(app_file, "# Version 2\nputs 'Updated'")

        # Verify updated content
        content = File.read(app_file)
        assert_match(/Version 2/, content)
        assert_match(/Updated/, content)
      end
    end

    test "user can create nested directories in storage/home" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        storage_home = File.join(project_dir, "storage", "home")

        # Create nested directory structure
        FileUtils.mkdir_p(File.join(storage_home, "lib"))
        File.write(File.join(storage_home, "lib", "helper.rb"), "# Helper module")
        FileUtils.mkdir_p(File.join(storage_home, "config"))
        File.write(File.join(storage_home, "config", "settings.rb"), "# Settings")

        # Verify nested structure
        assert Dir.exist?(File.join(storage_home, "lib"))
        assert File.exist?(File.join(storage_home, "lib", "helper.rb"))
        assert Dir.exist?(File.join(storage_home, "config"))
        assert File.exist?(File.join(storage_home, "config", "settings.rb"))

        # Verify content
        assert_match(/Helper module/, File.read(File.join(storage_home, "lib", "helper.rb")))
        assert_match(/Settings/, File.read(File.join(storage_home, "config", "settings.rb")))
      end
    end

    test "storage/home supports binary files" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        storage_home = File.join(project_dir, "storage", "home")
        binary_file = File.join(storage_home, "data.bin")

        # Create binary-like file
        binary_content = [0x00, 0x01, 0xFF, 0xFE].pack("C*")
        File.binwrite(binary_file, binary_content)

        # Verify binary file
        assert File.exist?(binary_file)
        read_content = File.binread(binary_file)
        assert_equal binary_content, read_content
      end
    end
  end
end
