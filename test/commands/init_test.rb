require "test_helper"
require "tmpdir"
require "fileutils"

class PraCommandsInitTest < PraTestCase
  # ptrk init コマンドのテスト

  sub_test_case "init command basic creation" do
    test "creates project directories" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Check that all required directories are created
          assert Dir.exist?("test-project/storage/home")
          assert Dir.exist?("test-project/patch")
          assert Dir.exist?("test-project/ptrk_env")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates required files" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Check that all required files are created
          assert File.exist?("test-project/.gitignore")
          assert File.exist?("test-project/.picoruby-env.yml")
          assert File.exist?("test-project/Gemfile")
          assert File.exist?("test-project/README.md")
          assert File.exist?("test-project/CLAUDE.md")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates patch subdirectories" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Check patch subdirectories
          assert Dir.exist?("test-project/patch/R2P2-ESP32")
          assert Dir.exist?("test-project/patch/picoruby-esp32")
          assert Dir.exist?("test-project/patch/picoruby")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates .picoruby-env.yml with valid YAML structure" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Load and verify YAML structure
          env_file = YAML.safe_load_file("test-project/.picoruby-env.yml")
          assert env_file.is_a?(Hash)
          assert_nil env_file["current"]
          assert env_file["environments"].is_a?(Hash)
          assert env_file["environments"].empty?
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates .gitignore with required entries" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Check .gitignore content
          gitignore = File.read("test-project/.gitignore")
          assert_match(%r{\.cache/}, gitignore)
          assert_match(%r{build/}, gitignore)
          assert_match(%r{ptrk_env/}, gitignore)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates Gemfile with picotorokko dependency" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Check Gemfile content
          gemfile = File.read("test-project/Gemfile")
          assert_match(/picotorokko/, gemfile)
          assert_match(/rubygems\.org/, gemfile)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "uses project name in generated files" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project with specific name
          initializer = Picotorokko::ProjectInitializer.new("my-app", {})
          initializer.initialize_project

          # Check README contains project name (with UTF-8 encoding)
          readme = File.read("my-app/README.md", encoding: "UTF-8")
          assert_match(/my-app/, readme)

          # Check CLAUDE.md contains project name (with UTF-8 encoding)
          claude = File.read("my-app/CLAUDE.md", encoding: "UTF-8")
          assert_match(/my-app/, claude)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates project in current directory if no name given" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Create a subdirectory and init without name
          Dir.mkdir("my-project")
          Dir.chdir("my-project")

          # Initialize without project name
          initializer = Picotorokko::ProjectInitializer.new(nil, {})
          initializer.initialize_project

          # Check that directories are created in current directory
          assert Dir.exist?("./storage/home")
          assert Dir.exist?("./patch")
          assert Dir.exist?("./ptrk_env")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates .gitkeep files in important directories" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Check for .gitkeep files
          assert File.exist?("test-project/ptrk_env/.gitkeep")
          assert File.exist?("test-project/storage/home/.gitkeep")
          assert File.exist?("test-project/patch/R2P2-ESP32/.gitkeep")
          assert File.exist?("test-project/patch/picoruby-esp32/.gitkeep")
          assert File.exist?("test-project/patch/picoruby/.gitkeep")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates patch README with instructions" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Check patch README exists and has content (with UTF-8 encoding)
          patch_readme = File.read("test-project/patch/README.md", encoding: "UTF-8")
          assert_match(/[Pp]atch/, patch_readme)
          assert_match(/export|apply/i, patch_readme)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates storage/home/app.rb with example code" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize a project
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Check app.rb exists
          app_rb = File.read("test-project/storage/home/app.rb")
          assert_match(/PicoRuby|application/i, app_rb)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  sub_test_case "init command with --with-ci option" do
    test "copies GitHub Actions workflow when --with-ci is enabled" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize with --with-ci option
          initializer = Picotorokko::ProjectInitializer.new("test-project", { "with_ci" => true })
          initializer.initialize_project

          # Check that GitHub Actions workflow is copied
          assert File.exist?("test-project/.github/workflows/esp32-build.yml")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "does not copy workflow when --with-ci is not specified" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize without --with-ci option
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Check that workflow is NOT copied
          assert !File.exist?("test-project/.github/workflows/esp32-build.yml")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end
end
