require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/picotorokko/commands/env"

class ScenarioPatchWorkflowTest < PicotorokkoTestCase
  # patch workflow シナリオテスト
  # Verify patch creation and application workflow

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

  sub_test_case "Scenario: patch workflow from export to application" do
    test "Step 1: Initial state has no patches directory" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Initial state: no patches directory
          assert_false Dir.exist?(Picotorokko::Env::PATCH_DIR),
                       "Initial state should have no patches/ directory"
        end
      end
    end

    test "Step 2: patch_diff shows changes in build directory" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment("20251122_120000", r2p2_info, esp32_info, picoruby_info)

          # Create build directory with git repository
          build_path = Picotorokko::Env.get_build_path("20251122_120000")
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

            # Modify file in build directory
            File.write("config.h", "#define VERSION 2")
          end

          # Run patch_diff
          output = capture_stdout do
            Picotorokko::Commands::Env.start(["patch_diff", "20251122_120000"])
          end

          # Verify output shows differences
          assert_match(/Patch Differences/, output)
          assert_match(/R2P2-ESP32/, output)
        end
      end
    end

    test "Step 3: patch_export creates patch files" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment("20251122_130000", r2p2_info, esp32_info, picoruby_info)

          # Create build directory with modified files
          build_path = Picotorokko::Env.get_build_path("20251122_130000")
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

            # Modify file
            File.write("Makefile", "all: build\nclean: rm -rf build")
          end

          # Run patch_export
          output = capture_stdout do
            Picotorokko::Commands::Env.start(["patch_export", "20251122_130000"])
          end

          # Verify patch files created
          assert_match(/Exporting patches from: 20251122_130000/, output)
          assert_match(/Patches exported/, output)

          patch_file = File.join(Picotorokko::Env::PATCH_DIR, "R2P2-ESP32", "Makefile")
          assert File.exist?(patch_file), "Patch file should be created"

          # Verify patch content
          patch_content = File.read(patch_file)
          assert_match(/diff --git/, patch_content)
          assert_match(/-all: build/, patch_content)
          assert_match(/\+all: build/, patch_content)
        end
      end
    end

    test "Steps 4-5: exported patches can be applied" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment("20251122_140000", r2p2_info, esp32_info, picoruby_info)

          # Create build directory
          build_path = Picotorokko::Env.get_build_path("20251122_140000")
          r2p2_work = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_work)

          Dir.chdir(r2p2_work) do
            system("git init -b main > /dev/null 2>&1")
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            system("git config commit.gpgsign false > /dev/null 2>&1")
            File.write("README.md", "# Original")
            system("git add . > /dev/null 2>&1")
            system('git commit -m "initial" > /dev/null 2>&1')
            File.write("README.md", "# Modified by user")
          end

          # Export patches
          capture_stdout do
            Picotorokko::Commands::Env.start(["patch_export", "20251122_140000"])
          end

          # Verify patch was exported
          patch_dir = File.join(Picotorokko::Env::PATCH_DIR, "R2P2-ESP32")
          assert Dir.exist?(patch_dir), "Patch directory should exist"

          # Simulate applying patch: read the diff and verify it contains changes
          patch_file = File.join(patch_dir, "README.md")
          if File.exist?(patch_file)
            patch_content = File.read(patch_file)
            # Patch file should contain diff that can be applied
            assert_match(/-# Original/, patch_content)
            assert_match(/\+# Modified by user/, patch_content)
          end

          # NOTE: Actually applying patches is done by `ptrk device build`
          # which copies patches/ to .ptrk_build/ - this is tested elsewhere
        end
      end
    end

    test "patch workflow handles multiple modified files" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment("20251122_150000", r2p2_info, esp32_info, picoruby_info)

          # Create build directory
          build_path = Picotorokko::Env.get_build_path("20251122_150000")
          r2p2_work = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_work)

          Dir.chdir(r2p2_work) do
            system("git init -b main > /dev/null 2>&1")
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            system("git config commit.gpgsign false > /dev/null 2>&1")

            # Create multiple files
            File.write("file1.c", "// Original 1")
            File.write("file2.c", "// Original 2")
            FileUtils.mkdir_p("src")
            File.write("src/file3.c", "// Original 3")
            system("git add . > /dev/null 2>&1")
            system('git commit -m "initial" > /dev/null 2>&1')

            # Modify all files
            File.write("file1.c", "// Modified 1")
            File.write("file2.c", "// Modified 2")
            File.write("src/file3.c", "// Modified 3")
          end

          # Export patches
          output = capture_stdout do
            Picotorokko::Commands::Env.start(["patch_export", "20251122_150000"])
          end

          # Verify all patches created
          assert_match(/3 file/, output)

          patch_dir = File.join(Picotorokko::Env::PATCH_DIR, "R2P2-ESP32")
          assert File.exist?(File.join(patch_dir, "file1.c"))
          assert File.exist?(File.join(patch_dir, "file2.c"))
          assert File.exist?(File.join(patch_dir, "src", "file3.c"))
        end
      end
    end
  end
end
