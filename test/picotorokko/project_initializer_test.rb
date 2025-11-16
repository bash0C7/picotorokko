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
end
