require_relative "../test_helper"

class PicotorokkoProjectInitializerTest < PraTestCase
  test "ProjectInitializer has setup_default_environment method" do
    tmpdir = Dir.mktmpdir
    project_name = "test_project"

    begin
      initializer = Picotorokko::ProjectInitializer.new(project_name, path: tmpdir)
      assert initializer.respond_to?(:setup_default_environment),
             "ProjectInitializer should have setup_default_environment method"
    ensure
      FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
    end
  end

  test "initialize_project handles setup_default_environment gracefully" do
    tmpdir = Dir.mktmpdir
    project_name = "test_project"

    begin
      # Mock setup_default_environment to avoid network calls
      original_method = Picotorokko::ProjectInitializer.instance_method(:setup_default_environment)
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment) do
        # Simulate successful completion without network call
      end

      initializer = Picotorokko::ProjectInitializer.new(project_name, path: tmpdir)
      # Should complete without error even with setup_default_environment mocked
      initializer.initialize_project

      # Verify project structure was created
      assert Dir.exist?(File.join(tmpdir, project_name, "storage", "home"))
    ensure
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment, original_method)
      FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
    end
  end

  test "initialize_project handles setup_default_environment errors gracefully" do
    tmpdir = Dir.mktmpdir
    project_name = "test_project"

    begin
      # Mock setup_default_environment to raise an error
      original_method = Picotorokko::ProjectInitializer.instance_method(:setup_default_environment)
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment) do
        raise StandardError, "Network error"
      end

      initializer = Picotorokko::ProjectInitializer.new(project_name, path: tmpdir)
      # Should complete without raising, despite error in setup_default_environment
      initializer.initialize_project

      # Verify project structure was still created
      assert Dir.exist?(File.join(tmpdir, project_name, "storage", "home"))
    ensure
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment, original_method)
      FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
    end
  end

  test "initialize_project creates test directory" do
    tmpdir = Dir.mktmpdir
    project_name = "test_project"

    begin
      # Mock setup_default_environment to avoid network calls
      original_method = Picotorokko::ProjectInitializer.instance_method(:setup_default_environment)
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment) do
        # No-op
      end

      initializer = Picotorokko::ProjectInitializer.new(project_name, path: tmpdir)
      initializer.initialize_project

      # Verify test directory was created
      test_dir = File.join(tmpdir, project_name, "test")
      assert Dir.exist?(test_dir), "test/ directory should be created"
    ensure
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment, original_method)
      FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
    end
  end

  test "initialize_project creates test template file" do
    tmpdir = Dir.mktmpdir
    project_name = "test_project"

    begin
      # Mock setup_default_environment to avoid network calls
      original_method = Picotorokko::ProjectInitializer.instance_method(:setup_default_environment)
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment) do
        # No-op
      end

      initializer = Picotorokko::ProjectInitializer.new(project_name, path: tmpdir)
      initializer.initialize_project

      # Verify test template was created
      test_file = File.join(tmpdir, project_name, "test", "app_test.rb")
      assert File.exist?(test_file), "test/app_test.rb template should be created"
    ensure
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment, original_method)
      FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
    end
  end

  test "test template includes Picotest examples" do
    tmpdir = Dir.mktmpdir
    project_name = "test_project"

    begin
      # Mock setup_default_environment to avoid network calls
      original_method = Picotorokko::ProjectInitializer.instance_method(:setup_default_environment)
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment) do
        # No-op
      end

      initializer = Picotorokko::ProjectInitializer.new(project_name, path: tmpdir)
      initializer.initialize_project

      # Read test template
      test_file = File.join(tmpdir, project_name, "test", "app_test.rb")
      content = File.read(test_file)

      # Verify Picotest examples are present
      assert_match(/class.*Test < Picotest::Test/, content, "Should inherit from Picotest::Test")
      assert_match(/stub_any_instance_of/, content, "Should include stub example")
      assert_match(/mock_any_instance_of/, content, "Should include mock example")
      assert_match(/assert_equal/, content, "Should include assertion example")
    ensure
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment, original_method)
      FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
    end
  end

  test "initialize_project creates .rubocop.yml with PicoRuby config" do
    tmpdir = Dir.mktmpdir
    project_name = "test_project"

    begin
      # Mock setup_default_environment to avoid network calls
      original_method = Picotorokko::ProjectInitializer.instance_method(:setup_default_environment)
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment) do
        # No-op
      end

      initializer = Picotorokko::ProjectInitializer.new(project_name, path: tmpdir)
      initializer.initialize_project

      # Verify .rubocop.yml was created
      rubocop_file = File.join(tmpdir, project_name, ".rubocop.yml")
      assert File.exist?(rubocop_file), ".rubocop.yml should be created"

      # Verify content
      content = File.read(rubocop_file, encoding: "UTF-8")
      assert_match(/TargetRubyVersion/, content, "Should specify target Ruby version")
      assert_match(/ptrk_env/, content, "Should exclude ptrk_env directory")
      assert_match(%r{Metrics/MethodLength}, content, "Should have MethodLength config")
    ensure
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment, original_method)
      FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
    end
  end

  test "CLAUDE.md includes PicoRuby development guide" do
    tmpdir = Dir.mktmpdir
    project_name = "test_project"

    begin
      # Mock setup_default_environment to avoid network calls
      original_method = Picotorokko::ProjectInitializer.instance_method(:setup_default_environment)
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment) do
        # No-op
      end

      initializer = Picotorokko::ProjectInitializer.new(project_name, path: tmpdir)
      initializer.initialize_project

      # Read CLAUDE.md with UTF-8 encoding for international characters
      claude_file = File.join(tmpdir, project_name, "CLAUDE.md")
      content = File.read(claude_file, encoding: "UTF-8")

      # Verify PicoRuby specific content
      assert_match(/mrbgem/, content, "Should mention mrbgems")
      assert_match(/I2C/, content, "Should mention I2C for peripherals")
      assert_match(/GPIO/, content, "Should mention GPIO")
      assert_match(/Memory Optimization/, content, "Should discuss memory optimization")
    ensure
      Picotorokko::ProjectInitializer.define_method(:setup_default_environment, original_method)
      FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
    end
  end

  test "validate_project_name! rejects uppercase letters" do
    initializer = Picotorokko::ProjectInitializer.new("TestProject")
    assert_raise(RuntimeError) do
      initializer.send(:validate_project_name!, "TestProject")
    end
  end

  test "validate_project_name! rejects special characters" do
    initializer = Picotorokko::ProjectInitializer.new("test-project!")
    assert_raise(RuntimeError) do
      initializer.send(:validate_project_name!, "test-project!")
    end
  end

  test "validate_project_name! rejects dots in name" do
    initializer = Picotorokko::ProjectInitializer.new("test.project")
    assert_raise(RuntimeError) do
      initializer.send(:validate_project_name!, "test.project")
    end
  end

  test "detect_git_author handles git command failure gracefully" do
    tmpdir = Dir.mktmpdir
    project_name = "test_project"

    begin
      # Create a temporary git repo with no user.name configured
      Dir.chdir(tmpdir) do
        `git init --quiet`
        `git config --local user.email "test@example.com"` # Only email, no name
      end

      initializer = Picotorokko::ProjectInitializer.new(project_name, path: tmpdir)
      author = initializer.send(:detect_git_author)
      # Should return nil or empty string when git config user.name is not set
      assert(author.nil? || author.empty?, "Should handle missing git user.name gracefully")
    ensure
      FileUtils.rm_rf(tmpdir) if tmpdir && Dir.exist?(tmpdir)
    end
  end
end
