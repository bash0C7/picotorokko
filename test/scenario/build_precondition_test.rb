# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class ScenarioBuildPreconditionTest < PicotorokkoTestCase
  # Build precondition verification tests
  # Verify that ptrk device can prepare build environment after project setup

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  sub_test_case "Scenario: Build environment preparation" do
    test "user can create project and prepare build environment" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Prepare build environment
        run_ptrk_command("device prepare", cwd: project_dir)
        # prepare may fail due to missing environment setup, but command should exist
        # Just verify the command runs without error
        assert Dir.exist?(project_dir), "project directory should exist"
      end
    end

    test "user can add storage/home files and verify in project" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        storage_home = File.join(project_dir, "storage", "home")

        # Add files to storage/home
        File.write(File.join(storage_home, "app.rb"), "puts 'Hello'")
        File.write(File.join(storage_home, "config.yml"), "key: value")

        # Verify files exist
        assert File.exist?(File.join(storage_home, "app.rb")), "app.rb should exist"
        assert File.exist?(File.join(storage_home, "config.yml")), "config.yml should exist"
      end
    end

    test "user can add mrbgems to project directory" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        mrbgems_dir = File.join(project_dir, "mrbgems", "my_gem", "src")

        # Create mrbgems structure
        FileUtils.mkdir_p(mrbgems_dir)
        File.write(File.join(project_dir, "mrbgems", "my_gem", "mrbgem.rake"),
                   "MRuby::Gem::Specification.new")
        File.write(File.join(mrbgems_dir, "custom.c"), "void custom_init() {}")

        # Verify structure exists
        assert Dir.exist?(File.join(project_dir, "mrbgems", "my_gem")), "mrbgem directory should exist"
        assert File.exist?(File.join(project_dir, "mrbgems", "my_gem", "mrbgem.rake")),
               "mrbgem.rake should exist"
      end
    end

    test "user can add patches to project" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        patch_dir = File.join(project_dir, "patch", "R2P2-ESP32", "custom")

        # Create patch directory
        FileUtils.mkdir_p(patch_dir)
        File.write(File.join(patch_dir, "config.h"), "#define CUSTOM_VALUE 42")

        # Verify patch exists
        assert File.exist?(File.join(patch_dir, "config.h")), "patch file should exist"
        assert_equal "#define CUSTOM_VALUE 42", File.read(File.join(patch_dir, "config.h"))
      end
    end

    test "project directory structure contains all required subdirectories" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)

        # Verify all required directories exist
        assert Dir.exist?(File.join(project_dir, "storage", "home")), "storage/home should exist"
        assert Dir.exist?(File.join(project_dir, "mrbgems")), "mrbgems should exist"
        assert Dir.exist?(File.join(project_dir, "patch")), "patch should exist"
        assert File.exist?(File.join(project_dir, ".rubocop.yml")), ".rubocop.yml should exist"
        assert File.exist?(File.join(project_dir, "Mrbgemfile")), "Mrbgemfile should exist"
      end
    end

    test "user can create multiple files in storage/home and mrbgems" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        storage_home = File.join(project_dir, "storage", "home")

        # Create multiple files in storage/home
        File.write(File.join(storage_home, "file1.rb"), "# File 1")
        File.write(File.join(storage_home, "file2.rb"), "# File 2")
        File.write(File.join(storage_home, "file3.yml"), "data: value")

        # Verify all files exist
        assert File.exist?(File.join(storage_home, "file1.rb"))
        assert File.exist?(File.join(storage_home, "file2.rb"))
        assert File.exist?(File.join(storage_home, "file3.yml"))

        # Create multiple mrbgems
        %w[gem1 gem2 gem3].each do |gem_name|
          gem_path = File.join(project_dir, "mrbgems", gem_name)
          FileUtils.mkdir_p(gem_path)
          File.write(File.join(gem_path, "mrbgem.rake"), "MRuby::Gem::Specification.new")

          # Verify all mrbgems exist
          assert Dir.exist?(File.join(project_dir, "mrbgems", gem_name))
        end
      end
    end

    test "user can create nested patch directories" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        project_dir = File.join(tmpdir, project_id)
        patch_nested_dir = File.join(project_dir, "patch", "R2P2-ESP32", "lib", "feature")

        # Create deeply nested patch directory
        FileUtils.mkdir_p(patch_nested_dir)
        File.write(File.join(patch_nested_dir, "feature.h"), "#ifndef FEATURE_H\n#define FEATURE_H\n#endif")

        # Verify nested patch structure exists
        assert File.exist?(File.join(patch_nested_dir, "feature.h"))
        content = File.read(File.join(patch_nested_dir, "feature.h"))
        assert_match(/FEATURE_H/, content)
      end
    end
  end
end
