require "test_helper"
require "tmpdir"
require "fileutils"

class ScenarioProjectLifecycleTest < PicotorokkoTestCase
  # project lifecycle scenario tests
  # Verify complete project lifecycle from creation through setup

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  sub_test_case "Scenario: project lifecycle from creation through development" do
    test "user can create complete project structure with ptrk new" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Verify complete project structure
        assert Dir.exist?(project_dir), "Project directory should be created"
        assert File.exist?(File.join(project_dir, "README.md")), "README.md should exist"
        assert File.exist?(File.join(project_dir, ".picoruby-env.yml")), "Environment file should exist"
        assert Dir.exist?(File.join(project_dir, "storage")), "storage/ directory should exist"
        assert Dir.exist?(File.join(project_dir, "storage", "home")), "storage/home/ should exist"
        assert Dir.exist?(File.join(project_dir, "mrbgems")), "mrbgems/ directory should exist"
        assert Dir.exist?(File.join(project_dir, "mrbgems", "applib")), "applib mrbgem should exist"

        # Verify project is ready for development
        assert File.exist?(File.join(project_dir, "mrbgems", "applib", "mrbgem.rake"))
        assert File.exist?(File.join(project_dir, "mrbgems", "applib", "mrblib", "applib.rb"))
        assert File.exist?(File.join(project_dir, "mrbgems", "applib", "src", "applib.c"))
      end
    end

    test "user can add custom mrbgems to project" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Generate additional mrbgems
        run_ptrk_command("mrbgems generate device_lib", cwd: project_dir)
        run_ptrk_command("mrbgems generate utils_lib", cwd: project_dir)

        # Verify all mrbgems exist
        assert Dir.exist?(File.join(project_dir, "mrbgems", "applib"))
        assert Dir.exist?(File.join(project_dir, "mrbgems", "device_lib"))
        assert Dir.exist?(File.join(project_dir, "mrbgems", "utils_lib"))

        # Verify structure of each mrbgem
        %w[applib device_lib utils_lib].each do |gem|
          assert File.exist?(File.join(project_dir, "mrbgems", gem, "mrbgem.rake"))
          assert Dir.exist?(File.join(project_dir, "mrbgems", gem, "mrblib"))
          assert Dir.exist?(File.join(project_dir, "mrbgems", gem, "src"))
        end
      end
    end

    test "user can add files to storage/home during development" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        storage_home = File.join(project_dir, "storage", "home")

        # Simulate developer adding files
        File.write(File.join(storage_home, "app.rb"), "puts 'Hello World'")
        File.write(File.join(storage_home, "config.yml"), "debug: true")
        FileUtils.mkdir_p(File.join(storage_home, "lib"))
        File.write(File.join(storage_home, "lib", "helper.rb"), "def help; end")

        # Verify files exist and can be read
        assert File.exist?(File.join(storage_home, "app.rb"))
        assert File.exist?(File.join(storage_home, "config.yml"))
        assert File.exist?(File.join(storage_home, "lib", "helper.rb"))

        # Verify content
        app_content = File.read(File.join(storage_home, "app.rb"))
        config_content = File.read(File.join(storage_home, "config.yml"))

        assert_match(/Hello World/, app_content)
        assert_match(/debug/, config_content)
      end
    end

    test "user can create patches during development" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # User creates patches for customization
        patch_dir = File.join(project_dir, "patch", "R2P2-ESP32")
        File.write(File.join(patch_dir, "custom_config.h"), "#define CUSTOM 1")

        # User creates custom build files
        FileUtils.mkdir_p(File.join(patch_dir, "custom"))
        File.write(File.join(patch_dir, "custom", "makefile"), "all: custom")

        # Verify patch structure
        assert File.exist?(File.join(patch_dir, "custom_config.h"))
        assert File.exist?(File.join(patch_dir, "custom", "makefile"))
      end
    end

    test "project integrates storage, mrbgems, and patches" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Add to storage/home
        File.write(File.join(project_dir, "storage", "home", "app.rb"), "# App")

        # Add custom mrbgem
        run_ptrk_command("mrbgems generate core_lib", cwd: project_dir)

        # Add patches
        File.write(File.join(project_dir, "patch", "R2P2-ESP32", "config.h"), "#define X 1")

        # Verify all three work together
        assert File.exist?(File.join(project_dir, "storage", "home", "app.rb"))
        assert Dir.exist?(File.join(project_dir, "mrbgems", "core_lib"))
        assert File.exist?(File.join(project_dir, "patch", "R2P2-ESP32", "config.h"))

        # Verify directory structure is complete
        assert Dir.exist?(File.join(project_dir, "test"))
        assert File.exist?(File.join(project_dir, "Mrbgemfile"))
        assert File.exist?(File.join(project_dir, ".rubocop.yml"))
      end
    end
  end
end
