require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/picotorokko/commands/new"
require_relative "../../lib/picotorokko/commands/mrbgems"

class ScenarioMrbgemsWorkflowTest < PicotorokkoTestCase
  # mrbgems workflow シナリオテスト
  # Verify mrbgems are correctly generated and included in builds

  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  # 標準出力をキャプチャするヘルパー
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  sub_test_case "Scenario: mrbgems workflow from project creation to build" do
    test "Step 1: ptrk new creates project with default mrbgems/app/" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # User scenario: ptrk new testapp
          initializer = Picotorokko::ProjectInitializer.new("testapp", {})
          initializer.initialize_project

          # Verify mrbgems/app/ is generated
          assert Dir.exist?("testapp/mrbgems/app"), "Should create mrbgems/app/ directory"
          assert Dir.exist?("testapp/mrbgems/app/mrblib"), "Should create mrblib directory"
          assert Dir.exist?("testapp/mrbgems/app/src"), "Should create src directory"
          assert File.exist?("testapp/mrbgems/app/mrbgem.rake"), "Should create mrbgem.rake"
          assert File.exist?("testapp/mrbgems/app/mrblib/app.rb"), "Should create app.rb"
          assert File.exist?("testapp/mrbgems/app/src/app.c"), "Should create app.c"
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Step 2: ptrk mrbgems generate creates custom mrbgem" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Setup: Create project first
          initializer = Picotorokko::ProjectInitializer.new("testapp", {})
          initializer.initialize_project

          # Move into project
          Dir.chdir("testapp")

          # User scenario: ptrk mrbgems generate mylib
          capture_stdout do
            Picotorokko::Commands::Mrbgems.start(["generate", "mylib"])
          end

          # Verify mrbgems/mylib/ is generated
          assert Dir.exist?("mrbgems/mylib"), "Should create mrbgems/mylib/ directory"
          assert Dir.exist?("mrbgems/mylib/mrblib"), "Should create mylib mrblib directory"
          assert Dir.exist?("mrbgems/mylib/src"), "Should create mylib src directory"
          assert File.exist?("mrbgems/mylib/mrbgem.rake"), "Should create mylib mrbgem.rake"
          assert File.exist?("mrbgems/mylib/mrblib/mylib.rb"), "Should create mylib.rb"
          assert File.exist?("mrbgems/mylib/src/mylib.c"), "Should create mylib.c"

          # Verify content uses correct names
          rake_content = File.read("mrbgems/mylib/mrbgem.rake")
          assert_match(/MRuby::Gem::Specification\.new\('mylib'\)/, rake_content)

          c_content = File.read("mrbgems/mylib/src/mylib.c")
          assert_match(/mrbc_mylib_init/, c_content)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Steps 3-4: Multiple mrbgems are created in project" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Setup: Create project with default app
          initializer = Picotorokko::ProjectInitializer.new("testapp", {})
          initializer.initialize_project

          Dir.chdir("testapp")

          # Generate second mrbgem
          capture_stdout do
            Picotorokko::Commands::Mrbgems.start(["generate", "mylib"])
          end

          # Generate third mrbgem
          capture_stdout do
            Picotorokko::Commands::Mrbgems.start(["generate", "utils"])
          end

          # Verify all mrbgems exist
          assert Dir.exist?("mrbgems/app"), "Should have app mrbgem"
          assert Dir.exist?("mrbgems/mylib"), "Should have mylib mrbgem"
          assert Dir.exist?("mrbgems/utils"), "Should have utils mrbgem"

          # Verify each has complete structure
          %w[app mylib utils].each do |gem_name|
            prefix = gem_name.downcase
            assert File.exist?("mrbgems/#{gem_name}/mrbgem.rake"),
                   "Should have mrbgem.rake for #{gem_name}"
            assert File.exist?("mrbgems/#{gem_name}/mrblib/#{prefix}.rb"),
                   "Should have #{prefix}.rb for #{gem_name}"
            assert File.exist?("mrbgems/#{gem_name}/src/#{prefix}.c"),
                   "Should have #{prefix}.c for #{gem_name}"
          end

          # Verify mrbgems are distinct
          app_rake = File.read("mrbgems/app/mrbgem.rake")
          mylib_rake = File.read("mrbgems/mylib/mrbgem.rake")
          assert_match(/Specification\.new\('app'\)/, app_rake)
          assert_match(/Specification\.new\('mylib'\)/, mylib_rake)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "mrbgems generate raises error when directory already exists" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Setup: Create project
          initializer = Picotorokko::ProjectInitializer.new("testapp", {})
          initializer.initialize_project

          Dir.chdir("testapp")

          # Try to generate mrbgem with same name as default
          error = assert_raises(RuntimeError) do
            capture_stdout do
              Picotorokko::Commands::Mrbgems.start(["generate", "app"])
            end
          end

          assert_match(/already exists/, error.message)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "generated mrbgems have correct class names in Ruby and C code" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Setup
          initializer = Picotorokko::ProjectInitializer.new("testapp", {})
          initializer.initialize_project

          Dir.chdir("testapp")

          # Generate with PascalCase name
          capture_stdout do
            Picotorokko::Commands::Mrbgems.start(["generate", "MyAwesomeLib"])
          end

          # Verify Ruby code uses PascalCase class name
          rb_content = File.read("mrbgems/MyAwesomeLib/mrblib/myawesomelib.rb")
          assert_match(/class MyAwesomeLib/, rb_content)

          # Verify C code uses lowercase for function names
          c_content = File.read("mrbgems/MyAwesomeLib/src/myawesomelib.c")
          assert_match(/mrbc_myawesomelib_init/, c_content)
          assert_match(/mrbc_define_class.*"MyAwesomeLib"/, c_content)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end
end
