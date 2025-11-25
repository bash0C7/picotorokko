require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/picotorokko/commands/new"
require_relative "../../lib/picotorokko/commands/env"

class ScenarioStorageHomeTest < PicotorokkoTestCase
  # storage/home workflow シナリオテスト
  # Verify storage/home files are correctly copied to build

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

  sub_test_case "Scenario: storage/home workflow" do
    test "Step 1: project creation includes storage/home directory" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project

          # Verify storage/home exists
          assert Dir.exist?("myapp/storage"), "storage/ should be created"
          assert Dir.exist?("myapp/storage/home"), "storage/home/ should be created"
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Steps 2-3: storage/home files are available in project" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project

          Dir.chdir("myapp")

          # Create test file in storage/home
          File.write("storage/home/app.rb", "# My app\nputs 'Hello'")

          # Verify file exists
          assert File.exist?("storage/home/app.rb")
          content = File.read("storage/home/app.rb")
          assert_match(/My app/, content)
          assert_match(/Hello/, content)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Steps 4-5: storage/home files can be updated" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project

          Dir.chdir("myapp")

          # Create initial file
          File.write("storage/home/app.rb", "# Version 1")
          assert_equal "# Version 1", File.read("storage/home/app.rb")

          # Update file
          File.write("storage/home/app.rb", "# Version 2\nputs 'Updated'")

          # Verify updated content
          content = File.read("storage/home/app.rb")
          assert_match(/Version 2/, content)
          assert_match(/Updated/, content)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "Step 6: nested directories in storage/home are supported" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project

          Dir.chdir("myapp")

          # Create nested directory structure
          FileUtils.mkdir_p("storage/home/lib")
          File.write("storage/home/lib/helper.rb", "# Helper module")
          FileUtils.mkdir_p("storage/home/config")
          File.write("storage/home/config/settings.rb", "# Settings")

          # Verify nested structure
          assert Dir.exist?("storage/home/lib")
          assert File.exist?("storage/home/lib/helper.rb")
          assert Dir.exist?("storage/home/config")
          assert File.exist?("storage/home/config/settings.rb")

          # Verify content
          assert_match(/Helper module/, File.read("storage/home/lib/helper.rb"))
          assert_match(/Settings/, File.read("storage/home/config/settings.rb"))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "storage/home supports binary files" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Create project
          initializer = Picotorokko::ProjectInitializer.new("myapp", {})
          initializer.initialize_project

          Dir.chdir("myapp")

          # Create binary-like file
          binary_content = [0x00, 0x01, 0xFF, 0xFE].pack("C*")
          File.binwrite("storage/home/data.bin", binary_content)

          # Verify binary file
          assert File.exist?("storage/home/data.bin")
          read_content = File.binread("storage/home/data.bin")
          assert_equal binary_content, read_content
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end
end
