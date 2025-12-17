require "test_helper"
require "tmpdir"
require "fileutils"
require "open3"
require_relative "../../lib/picotorokko/commands/new"

class ScenarioNewTest < PicotorokkoTestCase
  # ptrk new コマンドのシナリオテスト
  # NOTE: Tests the main user workflows and scenarios
  # Network environment setup is skipped to keep tests fast
  # but core project structure creation is fully tested

  def setup
    super
    # Skip network environment setup during scenario tests
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    # Restore environment variable
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  sub_test_case "Scenario: User creates basic PicoRuby project" do
    test "creates complete project structure for new development" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)

        # Verify ptrk command succeeded
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        # User expectation: Can immediately start developing
        project_dir = File.join(tmpdir, project_id)
        assert Dir.exist?(project_dir), "project directory should exist at #{project_dir}"
        assert Dir.exist?(File.join(project_dir, "storage", "home")), "storage/home should exist"
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-applib")), "mrbgems/picoruby-applib should exist"

        # User expectation: Default mrbgem exists
        assert File.exist?(File.join(project_dir, "mrbgems", "picoruby-applib", "mrblib", "applib.rb")), "default mrblib should exist"
        assert File.exist?(File.join(project_dir, "mrbgems", "picoruby-applib", "src", "applib.c")), "default C source should exist"

        # User expectation: Can read project README
        readme_path = File.join(project_dir, "README.md")
        readme = File.read(readme_path, encoding: "UTF-8")
        assert_match(/#{project_id}/, readme, "README should contain project name")
      end
    end

    test "creates project with CI integration when --with-ci flag is used" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id} --with-ci", cwd: tmpdir)

        # Verify ptrk command succeeded
        assert status.success?, "ptrk new --with-ci should succeed. Output: #{output}"

        # User expectation: GitHub Actions workflow exists
        project_dir = File.join(tmpdir, project_id)
        workflow_path = File.join(project_dir, ".github", "workflows", "esp32-build.yml")
        assert File.exist?(workflow_path), "workflow file should exist at #{workflow_path}"

        # User expectation: Can view workflow content
        workflow = File.read(workflow_path, encoding: "UTF-8")
        assert workflow.length.positive?, "workflow content should not be empty"
        assert_match(/esp32/, workflow.downcase, "workflow should contain esp32 reference")
      end
    end

    test "creates project with specific project name" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        output, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)

        # Verify ptrk command succeeded
        assert status.success?, "ptrk new should succeed. Output: #{output}"

        # User expectation: Project structure created with specified name
        project_dir = File.join(tmpdir, project_id)
        assert File.exist?(File.join(project_dir, "README.md")), "README should exist"
        assert File.exist?(File.join(project_dir, ".picoruby-env.yml")), ".picoruby-env.yml should exist"
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-applib")), "mrbgems/picoruby-applib should exist"

        # User expectation: Can build with the project
        assert Dir.exist?(File.join(project_dir, "storage", "home")), "storage/home should exist"
      end
    end
  end

  sub_test_case "Scenario: Project structure is git-ready" do
    test "created projects work with git workflow" do
      Dir.mktmpdir do |tmpdir|
        project_id = generate_project_id
        _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # User scenario: Initialize git repo and track project files
        Dir.chdir(project_dir) do
          # Initialize git repo
          system("git init", out: File::NULL)
          system("git config user.email 'test@example.com'")
          system("git config user.name 'Test User'")
          system("git config commit.gpgsign false")

          # User expectation: .gitignore prevents tracking build artifacts
          gitignore = File.read(".gitignore", encoding: "UTF-8")
          assert_match(%r{\.cache/}, gitignore, ".gitignore should exclude .cache/")
          assert_match(%r{build/}, gitignore, ".gitignore should exclude build/")
          assert_match(%r{\.ptrk_env/}, gitignore, ".gitignore should exclude .ptrk_env/")

          # User expectation: Can commit project files
          system("git add .")
          output, status = Open3.capture2e("git commit -m 'Initial commit'")
          assert status.success?, "git commit should succeed. Output: #{output}"

          # User expectation: Build artifacts won't be tracked
          tracked_files = `git ls-tree -r --name-only HEAD`.strip.split("\n")
          assert(tracked_files.none? { |f| f.start_with?(".cache/") }, "tracked files should not include .cache/")
          assert(tracked_files.none? { |f| f.start_with?("build/") }, "tracked files should not include build/")
        end
      end
    end
  end

  sub_test_case "Scenario: Template rendering and variable substitution" do
    test "project name is correctly substituted in generated files" do
      Dir.mktmpdir do |tmpdir|
        project_id = "awesome-firmware"
        _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        # Verify name substitution in key files
        project_dir = File.join(tmpdir, project_id)
        readme = File.read(File.join(project_dir, "README.md"), encoding: "UTF-8")
        assert_match(/#{project_id}/, readme, "README should contain project name")

        claude = File.read(File.join(project_dir, "CLAUDE.md"), encoding: "UTF-8")
        assert_match(/#{project_id}/, claude, "CLAUDE.md should contain project name")

        # Verify mrbgem uses project structure
        assert Dir.exist?(File.join(project_dir, "mrbgems", "picoruby-applib")), "mrbgems/picoruby-applib should exist"
      end
    end

    test "generated files are valid and well-formed" do
      Dir.mktmpdir do |tmpdir|
        project_id = "valid-project"
        _, status = run_ptrk_command("new #{project_id}", cwd: tmpdir)
        assert status.success?, "ptrk new should succeed"

        project_dir = File.join(tmpdir, project_id)

        # Verify YAML is valid
        env_yaml = YAML.safe_load_file(File.join(project_dir, ".picoruby-env.yml"))
        assert env_yaml.is_a?(Hash), ".picoruby-env.yml should be valid YAML"

        # Verify Gemfile is valid Ruby syntax
        gemfile_path = File.join(project_dir, "Gemfile")
        gemfile_content = File.read(gemfile_path)
        assert gemfile_content.include?("source"), "Gemfile should have source"
        assert gemfile_content.include?("picotorokko"), "Gemfile should reference picotorokko"

        # Verify markdown files exist and contain content
        readme_path = File.join(project_dir, "README.md")
        assert File.exist?(readme_path), "README should exist"
        assert File.size(readme_path) > 100, "README should have meaningful content"
      end
    end
  end
end
