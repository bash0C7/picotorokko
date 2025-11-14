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
end
