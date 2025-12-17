require "test_helper"
require "tmpdir"
require "fileutils"

class ScenarioPhase5E2ETest < PicotorokkoTestCase
  # Phase 5 end-to-end verification scenario tests
  # Codify the manual e2e verification performed in Phase 5

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  sub_test_case "Scenario: Phase 5 e2e verification" do
    test "ptrk new creates project structure" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Verify project structure
        assert Dir.exist?(project_dir)
        assert File.exist?(File.join(project_dir, "README.md"))
        assert File.exist?(File.join(project_dir, ".picoruby-env.yml"))
        assert Dir.exist?(File.join(project_dir, "storage", "home"))
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-applib"))
      end
    end

    test "project has mrbgems structure with expected files" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        applib_gem = File.join(project_dir, "mrbgems", "picoruby-applib")

        # Verify mrbgems structure
        assert Dir.exist?(applib_gem)
        assert File.exist?(File.join(applib_gem, "mrbgem.rake"))
        assert File.exist?(File.join(applib_gem, "mrblib", "applib.rb"))
        assert File.exist?(File.join(applib_gem, "src", "applib.c"))
        assert File.exist?(File.join(applib_gem, "README.md"))

        # Verify mrbgem.rake content
        rake_content = File.read(File.join(applib_gem, "mrbgem.rake"))
        assert_match(/MRuby::Gem::Specification/, rake_content)
      end
    end

    test "project structure includes configuration files" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Verify configuration files
        assert File.exist?(File.join(project_dir, ".rubocop.yml"))
        assert File.exist?(File.join(project_dir, "Mrbgemfile"))
        assert File.exist?(File.join(project_dir, "CLAUDE.md"))
        assert File.exist?(File.join(project_dir, ".picoruby-env.yml"))
      end
    end

    test "storage/home directory exists and is writable" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        storage_home = File.join(project_dir, "storage", "home")

        # Verify storage/home exists
        assert Dir.exist?(storage_home)

        # Verify writable
        File.write(File.join(storage_home, "test.rb"), "# Test file")
        assert File.exist?(File.join(storage_home, "test.rb"))
        content = File.read(File.join(storage_home, "test.rb"))
        assert_equal "# Test file", content
      end
    end

    test "project has required directory structure for patches and environments" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Verify patch directories
        assert Dir.exist?(File.join(project_dir, "patch", "R2P2-ESP32"))
        assert Dir.exist?(File.join(project_dir, "patch", "picoruby-esp32"))
        assert Dir.exist?(File.join(project_dir, "patch", "picoruby"))

        # Verify environment directory
        assert Dir.exist?(File.join(project_dir, ".ptrk_env"))
      end
    end
  end
end
