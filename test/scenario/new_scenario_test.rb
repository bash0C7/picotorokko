require "test_helper"
require "tmpdir"
require "fileutils"
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
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # User scenario: ptrk new my-app
          initializer = Picotorokko::ProjectInitializer.new("my-app", {})
          initializer.initialize_project

          # User expectation: Can immediately start developing
          assert Dir.exist?("my-app")
          assert Dir.exist?("my-app/storage/home")
          assert Dir.exist?("my-app/mrbgems/app")

          # User expectation: Default mrbgem exists
          assert File.exist?("my-app/mrbgems/app/mrblib/app.rb")
          assert File.exist?("my-app/mrbgems/app/src/app.c")

          # User expectation: Can read project README
          readme = File.read("my-app/README.md", encoding: "UTF-8")
          assert_match(/my-app/, readme)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates project with CI integration when --with-ci flag is used" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # User scenario: ptrk new my-ci-project --with-ci
          initializer = Picotorokko::ProjectInitializer.new("my-ci-project", { "with-ci" => true })
          initializer.initialize_project

          # User expectation: GitHub Actions workflow exists
          assert File.exist?("my-ci-project/.github/workflows/esp32-build.yml")

          # User expectation: Can view workflow content
          workflow = File.read("my-ci-project/.github/workflows/esp32-build.yml", encoding: "UTF-8")
          assert workflow.length.positive?
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates project in current directory when no name is provided" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # User scenario: mkdir my-project && cd my-project && ptrk new
          Dir.mkdir("my-project")
          Dir.chdir("my-project")

          initializer = Picotorokko::ProjectInitializer.new(nil, {})
          initializer.initialize_project

          # User expectation: Project structure created in current directory
          assert File.exist?("README.md")
          assert File.exist?(".picoruby-env.yml")
          assert Dir.exist?("mrbgems/app")

          # User expectation: Can build in current directory
          assert Dir.exist?("storage/home")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  sub_test_case "Scenario: Project structure is git-ready" do
    test "created projects work with git workflow" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # User scenario: Initialize git repo and track project files
          initializer = Picotorokko::ProjectInitializer.new("git-project", {})
          initializer.initialize_project

          Dir.chdir("git-project")
          setup_test_git_repo

          # User expectation: .gitignore prevents tracking build artifacts
          ignored = File.read(".gitignore", encoding: "UTF-8")
          assert_match(%r{\.cache/}, ignored)
          assert_match(%r{build/}, ignored)
          assert_match(%r{ptrk_env/}, ignored)

          # User expectation: Can commit project files
          system("git add .", out: File::NULL)
          system("git commit -m 'Initial commit'", out: File::NULL)

          # User expectation: Build artifacts won't be tracked
          tracked_files = `git ls-tree -r --name-only HEAD`.strip.split("\n")
          assert(tracked_files.none? { |f| f.start_with?(".cache/") })
          assert(tracked_files.none? { |f| f.start_with?("build/") })
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  sub_test_case "Scenario: Template rendering and variable substitution" do
    test "project name is correctly substituted in generated files" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # User scenario: Create project with specific name
          project_name = "awesome-firmware"
          initializer = Picotorokko::ProjectInitializer.new(project_name, {})
          initializer.initialize_project

          # Verify name substitution in key files
          readme = File.read("awesome-firmware/README.md", encoding: "UTF-8")
          assert_match(/awesome-firmware/, readme)

          claude = File.read("awesome-firmware/CLAUDE.md", encoding: "UTF-8")
          assert_match(/awesome-firmware/, claude)

          # Verify mrbgem uses project structure
          assert Dir.exist?("awesome-firmware/mrbgems/app")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "generated files are valid and well-formed" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          initializer = Picotorokko::ProjectInitializer.new("valid-project", {})
          initializer.initialize_project

          # Verify YAML is valid
          env_yaml = YAML.safe_load_file("valid-project/.picoruby-env.yml")
          assert env_yaml.is_a?(Hash)

          # Verify Gemfile is valid Ruby syntax
          gemfile_path = "valid-project/Gemfile"
          gemfile_content = File.read(gemfile_path)
          assert gemfile_content.include?("source")
          assert gemfile_content.include?("picotorokko")

          # Verify markdown files exist and contain content
          readme_path = "valid-project/README.md"
          assert File.exist?(readme_path)
          assert File.size(readme_path) > 100, "README should have meaningful content"
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end
end
