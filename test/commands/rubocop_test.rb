require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsRubocopTest < Test::Unit::TestCase
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def with_stdin(input)
    original_stdin = $stdin
    $stdin = StringIO.new(input)
    yield
  ensure
    $stdin = original_stdin
  end

  sub_test_case "rubocop setup basic functionality" do
    test "copies template files to current directory" do
      output = capture_stdout do
        Pra::Commands::Rubocop.start(["setup"])
      end

      assert_match(/✅ RuboCop configuration has been set up!/, output)
      assert_match(/Next steps:/, output)

      assert_true(File.exist?(".rubocop.yml"))
      assert_true(File.directory?("lib/rubocop/cop/picoruby"))
      assert_true(File.exist?("lib/rubocop/cop/picoruby/unsupported_method.rb"))
      assert_true(File.directory?("scripts"))
      assert_true(File.exist?("scripts/update_methods.rb"))
      assert_true(File.directory?("data"))
    end
  end

  sub_test_case "rubocop setup prompts" do
    test "prompts for overwrite when .rubocop.yml exists and user declines" do
      FileUtils.touch(".rubocop.yml")

      output = capture_stdout do
        with_stdin("n\n") do
          Pra::Commands::Rubocop.start(["setup"])
        end
      end

      assert_match(/Skipped: \.rubocop\.yml/, output)
    end

    test "overwrites .rubocop.yml when user confirms" do
      FileUtils.touch(".rubocop.yml")
      File.write(".rubocop.yml", "old content")

      output = capture_stdout do
        with_stdin("y\n") do
          Pra::Commands::Rubocop.start(["setup"])
        end
      end

      assert_match(/✅ Copied: \.rubocop\.yml/, output)

      content = File.read(".rubocop.yml")
      assert_not_equal("old content", content)
      assert_match(/AllCops:/, content)
    end
  end

  sub_test_case "rubocop setup file content" do
    test "copies directory structure correctly" do
      capture_stdout do
        Pra::Commands::Rubocop.start(["setup"])
      end

      assert_true(File.exist?("lib/rubocop/cop/picoruby/unsupported_method.rb"))

      cop_content = File.read("lib/rubocop/cop/picoruby/unsupported_method.rb")
      assert_match(/class UnsupportedMethod/, cop_content)

      script_content = File.read("scripts/update_methods.rb")
      assert_match(/MethodDatabaseUpdater/, script_content)
    end
  end

  sub_test_case "rubocop update missing script" do
    test "fails if scripts/update_methods.rb does not exist" do
      assert_raises(SystemExit) do
        capture_stdout do
          Pra::Commands::Rubocop.start(["update"])
        end
      end
    end
  end

  sub_test_case "rubocop update script execution" do
    test "executes the update script if it exists" do
      FileUtils.mkdir_p("scripts")
      File.write("scripts/update_methods.rb", '#!/usr/bin/env ruby; puts "test"')
      File.chmod(0o755, "scripts/update_methods.rb")

      output = capture_stdout do
        Pra::Commands::Rubocop.start(["update"])
      end

      assert_match(/🚀 Running method database update.../, output)
    end

    test "fails when update script exits with error" do
      FileUtils.mkdir_p("scripts")
      File.write("scripts/update_methods.rb", "#!/usr/bin/env ruby; exit 1")
      File.chmod(0o755, "scripts/update_methods.rb")

      assert_raises(SystemExit) do
        capture_stdout do
          Pra::Commands::Rubocop.start(["update"])
        end
      end
    end
  end

  sub_test_case "rubocop file copy operations" do
    test "copies single file (.rubocop.yml)" do
      capture_stdout do
        Pra::Commands::Rubocop.start(["setup"])
      end

      assert_true(File.exist?(".rubocop.yml"))
      content = File.read(".rubocop.yml")
      assert_match(/AllCops:/, content)
      assert_match(/require:/, content)
    end
  end

  sub_test_case "rubocop directory copy operations" do
    test "copies directories (lib, scripts, data)" do
      capture_stdout do
        Pra::Commands::Rubocop.start(["setup"])
      end

      assert_true(File.directory?("lib"))
      assert_true(File.directory?("lib/rubocop"))
      assert_true(File.directory?("lib/rubocop/cop"))
      assert_true(File.directory?("lib/rubocop/cop/picoruby"))
      assert_true(File.directory?("scripts"))
      assert_true(File.directory?("data"))
    end

    test "handles deletion of existing directory during overwrite" do
      # Pre-create lib directory with old content
      FileUtils.mkdir_p("lib/rubocop/cop/picoruby")
      File.write("lib/rubocop/cop/picoruby/old_cop.rb", "old code")

      capture_stdout do
        with_stdin("y\n") do
          Pra::Commands::Rubocop.start(["setup"])
        end
      end

      # Old file should be replaced with new content
      cop_content = File.read("lib/rubocop/cop/picoruby/unsupported_method.rb")
      assert_match(/UnsupportedMethod/, cop_content)
      assert_false(File.exist?("lib/rubocop/cop/picoruby/old_cop.rb"))
    end
  end
end
