require "test_helper"
require "tmpdir"
require "fileutils"

class ScenarioPatchWorkflowTest < PicotorokkoTestCase
  # patch workflow scenario tests
  # Verify patch creation and directory structure

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  sub_test_case "Scenario: patch workflow from project creation" do
    test "project has patch directory structure" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Verify patch directory structure
        assert Dir.exist?(File.join(project_dir, "patch")), "patch/ should exist"
        assert Dir.exist?(File.join(project_dir, "patch", "R2P2-ESP32")),
               "patch/R2P2-ESP32/ should exist"
        assert Dir.exist?(File.join(project_dir, "patch", "picoruby-esp32")),
               "patch/picoruby-esp32/ should exist"
        assert Dir.exist?(File.join(project_dir, "patch", "picoruby")),
               "patch/picoruby/ should exist"
      end
    end

    test "user can create patch files for R2P2-ESP32" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        patch_dir = File.join(project_dir, "patch", "R2P2-ESP32")

        # Create patch file
        File.write(File.join(patch_dir, "config.h"), "#define CUSTOM_VALUE 42")

        # Verify patch file exists
        assert File.exist?(File.join(patch_dir, "config.h"))
        content = File.read(File.join(patch_dir, "config.h"))
        assert_match(/CUSTOM_VALUE/, content)
      end
    end

    test "user can create nested patch files" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        patch_dir = File.join(project_dir, "patch", "R2P2-ESP32", "custom", "lib")

        # Create nested patch directory
        FileUtils.mkdir_p(patch_dir)
        File.write(File.join(patch_dir, "feature.h"), "#define FEATURE 1")

        # Verify nested patch structure
        assert File.exist?(File.join(patch_dir, "feature.h"))
        content = File.read(File.join(patch_dir, "feature.h"))
        assert_match(/FEATURE/, content)
      end
    end

    test "user can create patch files for picoruby-esp32 and picoruby" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Create patches for different repositories
        r2p2_patch = File.join(project_dir, "patch", "R2P2-ESP32", "app.c")
        esp32_patch = File.join(project_dir, "patch", "picoruby-esp32", "config.c")
        picoruby_patch = File.join(project_dir, "patch", "picoruby", "main.c")

        File.write(r2p2_patch, "// R2P2-ESP32 patch")
        File.write(esp32_patch, "// picoruby-esp32 patch")
        File.write(picoruby_patch, "// picoruby patch")

        # Verify all patches exist
        assert File.exist?(r2p2_patch)
        assert File.exist?(esp32_patch)
        assert File.exist?(picoruby_patch)
      end
    end

    test "patch directory can contain multiple patch files" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        patch_dir = File.join(project_dir, "patch", "R2P2-ESP32")

        # Create multiple patch files
        File.write(File.join(patch_dir, "config.h"), "#define CONFIG 1")
        File.write(File.join(patch_dir, "build.mk"), "BUILD_CONFIG=custom")
        FileUtils.mkdir_p(File.join(patch_dir, "src"))
        File.write(File.join(patch_dir, "src", "custom.c"), "void custom() {}")

        # Verify all patches exist
        assert File.exist?(File.join(patch_dir, "config.h"))
        assert File.exist?(File.join(patch_dir, "build.mk"))
        assert File.exist?(File.join(patch_dir, "src", "custom.c"))

        # Verify content
        config = File.read(File.join(patch_dir, "config.h"))
        build = File.read(File.join(patch_dir, "build.mk"))
        custom = File.read(File.join(patch_dir, "src", "custom.c"))

        assert_match(/CONFIG/, config)
        assert_match(/BUILD_CONFIG/, build)
        assert_match(/custom/, custom)
      end
    end
  end
end
