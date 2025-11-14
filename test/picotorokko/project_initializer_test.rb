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
end
