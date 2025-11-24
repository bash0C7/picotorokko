require "test_helper"
require "tmpdir"
require "fileutils"

class PatchCommandTest < PicotorokkoTestCase
  def setup
    super
    ENV["PTRK_SKIP_ENV_SETUP"] = "1"
  end

  def teardown
    ENV.delete("PTRK_SKIP_ENV_SETUP")
    super
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  sub_test_case "ptrk patch list" do
    test "shows empty message when no patches exist" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          output = capture_stdout do
            Picotorokko::Commands::Patch.start(["list"])
          end

          assert_match(/No patches found/, output)
        end
      end
    end

    test "lists patch files when they exist" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create patch files in correct location
          patch_dir = File.join(Picotorokko::Env.patch_dir, "R2P2-ESP32")
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, "config.h"), "diff content")
          FileUtils.mkdir_p(File.join(patch_dir, "src"))
          File.write(File.join(patch_dir, "src", "main.c"), "diff content")

          output = capture_stdout do
            Picotorokko::Commands::Patch.start(["list"])
          end

          assert_match(%r{R2P2-ESP32/config\.h}, output)
          assert_match(%r{R2P2-ESP32/src/main\.c}, output)
        end
      end
    end
  end

  sub_test_case "ptrk patch diff" do
    test "shows differences between build and patch" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment("20251124_120000", r2p2_info, esp32_info, picoruby_info)
          Picotorokko::Env.set_current_env("20251124_120000")

          # Create build directory with git repository
          build_path = Picotorokko::Env.get_build_path("20251124_120000")
          r2p2_work = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_work)

          Dir.chdir(r2p2_work) do
            system("git init -b main > /dev/null 2>&1")
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            system("git config commit.gpgsign false > /dev/null 2>&1")
            File.write("config.h", "#define VERSION 1")
            system("git add . > /dev/null 2>&1")
            system('git commit -m "initial" > /dev/null 2>&1')
            File.write("config.h", "#define VERSION 2")
          end

          output = capture_stdout do
            Picotorokko::Commands::Patch.start(["diff"])
          end

          assert_match(/Patch Differences/, output)
          assert_match(/R2P2-ESP32/, output)
        end
      end
    end

    test "uses specified environment" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment("20251124_130000", r2p2_info, esp32_info, picoruby_info)

          # Create build directory
          build_path = Picotorokko::Env.get_build_path("20251124_130000")
          r2p2_work = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_work)

          Dir.chdir(r2p2_work) do
            system("git init -b main > /dev/null 2>&1")
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            system("git config commit.gpgsign false > /dev/null 2>&1")
            File.write("test.c", "// test")
            system("git add . > /dev/null 2>&1")
            system('git commit -m "initial" > /dev/null 2>&1')
          end

          output = capture_stdout do
            Picotorokko::Commands::Patch.start(["diff", "20251124_130000"])
          end

          assert_match(/20251124_130000/, output)
        end
      end
    end
  end

  sub_test_case "ptrk patch export" do
    test "exports patches from build directory" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment("20251124_140000", r2p2_info, esp32_info, picoruby_info)
          Picotorokko::Env.set_current_env("20251124_140000")

          # Create build directory with modified files
          build_path = Picotorokko::Env.get_build_path("20251124_140000")
          r2p2_work = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_work)

          Dir.chdir(r2p2_work) do
            system("git init -b main > /dev/null 2>&1")
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            system("git config commit.gpgsign false > /dev/null 2>&1")
            File.write("Makefile", "all: build")
            system("git add . > /dev/null 2>&1")
            system('git commit -m "initial" > /dev/null 2>&1')
            File.write("Makefile", "all: build\nclean: rm -rf build")
          end

          output = capture_stdout do
            Picotorokko::Commands::Patch.start(["export"])
          end

          assert_match(/Exporting patches/, output)
          assert_match(/Patches exported/, output)

          # Verify patch file created
          patch_file = File.join(Picotorokko::Env.patch_dir, "R2P2-ESP32", "Makefile")
          assert File.exist?(patch_file), "Patch file should be created"
        end
      end
    end

    test "shows error when no current environment is set" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          error = assert_raises(RuntimeError) do
            capture_stdout do
              Picotorokko::Commands::Patch.start(["export"])
            end
          end

          assert_match(/No environment specified/, error.message)
        end
      end
    end

    test "removes old patches that no longer have changes" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment("20251124_150000", r2p2_info, esp32_info, picoruby_info)
          Picotorokko::Env.set_current_env("20251124_150000")

          # Create old patches that should be removed
          patch_dir = Picotorokko::Env.patch_dir
          old_patch = File.join(patch_dir, "R2P2-ESP32", "old_file.c")
          FileUtils.mkdir_p(File.dirname(old_patch))
          File.write(old_patch, "// old patch content")

          # Create build directory with different modified file
          build_path = Picotorokko::Env.get_build_path("20251124_150000")
          r2p2_work = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_work)

          Dir.chdir(r2p2_work) do
            system("git init -b main > /dev/null 2>&1")
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            system("git config commit.gpgsign false > /dev/null 2>&1")
            File.write("new_file.c", "// original")
            system("git add . > /dev/null 2>&1")
            system('git commit -m "initial" > /dev/null 2>&1')
            # Modify new_file.c only
            File.write("new_file.c", "// modified")
          end

          # Export should remove old patches
          capture_stdout do
            Picotorokko::Commands::Patch.start(["export"])
          end

          # Old patch should be removed
          assert_false File.exist?(old_patch), "Old patch should be removed"

          # New patch should exist
          new_patch = File.join(patch_dir, "R2P2-ESP32", "new_file.c")
          assert File.exist?(new_patch), "New patch should be created"
        end
      end
    end
  end
end
