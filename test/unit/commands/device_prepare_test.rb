require "test_helper"
require "tmpdir"
require "fileutils"

class DevicePrepareTest < PicotorokkoTestCase
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

  sub_test_case "ptrk device prepare" do
    test "creates build directory from environment" do
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

          # Create env directory (source)
          env_path = File.join(Picotorokko::Env::ENV_DIR, "20251124_120000")
          r2p2_env = File.join(env_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_env)
          File.write(File.join(r2p2_env, "Rakefile"), "task :build")

          output = capture_stdout do
            Picotorokko::Commands::Device.start(["prepare"])
          end

          assert_match(/Preparing build environment/, output)
          assert_match(/Build environment prepared/, output)

          # Verify build directory created
          build_path = Picotorokko::Env.get_build_path("20251124_120000")
          assert Dir.exist?(build_path), "Build directory should be created"
          assert Dir.exist?(File.join(build_path, "R2P2-ESP32")), "R2P2-ESP32 should be copied"
        end
      end
    end

    test "deletes and recreates existing build directory" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Setup environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          Picotorokko::Env.set_environment("20251124_130000", r2p2_info, esp32_info, picoruby_info)
          Picotorokko::Env.set_current_env("20251124_130000")

          # Create env directory (source)
          env_path = File.join(Picotorokko::Env::ENV_DIR, "20251124_130000")
          r2p2_env = File.join(env_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_env)
          File.write(File.join(r2p2_env, "Rakefile"), "task :build")

          # First prepare
          capture_stdout do
            Picotorokko::Commands::Device.start(["prepare"])
          end

          # Add user modification to build directory
          build_path = Picotorokko::Env.get_build_path("20251124_130000")
          user_file = File.join(build_path, "R2P2-ESP32", "user_modification.txt")
          File.write(user_file, "user content")

          # Second prepare should delete and recreate
          output = capture_stdout do
            Picotorokko::Commands::Device.start(["prepare"])
          end

          assert_match(/Preparing build environment/, output)
          assert_match(/Build environment prepared/, output)
          assert !File.exist?(user_file), "User modification should be deleted"
          assert Dir.exist?(build_path), "Build directory should be recreated"
          assert Dir.exist?(File.join(build_path, "R2P2-ESP32")), "R2P2-ESP32 should be recreated"
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
          Picotorokko::Env.set_environment("20251124_140000", r2p2_info, esp32_info, picoruby_info)

          # Create env directory
          env_path = File.join(Picotorokko::Env::ENV_DIR, "20251124_140000")
          r2p2_env = File.join(env_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_env)
          File.write(File.join(r2p2_env, "Rakefile"), "task :build")

          output = capture_stdout do
            Picotorokko::Commands::Device.start(["prepare", "--env", "20251124_140000"])
          end

          assert_match(/20251124_140000/, output)

          # Verify build directory created
          build_path = Picotorokko::Env.get_build_path("20251124_140000")
          assert Dir.exist?(build_path), "Build directory should be created"
        end
      end
    end

    test "applies patches during prepare" do
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

          # Create env directory
          env_path = File.join(Picotorokko::Env::ENV_DIR, "20251124_150000")
          r2p2_env = File.join(env_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_env)
          File.write(File.join(r2p2_env, "Rakefile"), "task :build")
          File.write(File.join(r2p2_env, "config.h"), "#define VERSION 1")

          # Create patch file (simple file copy, not diff)
          patch_dir = File.join(Picotorokko::Env.patch_dir, "R2P2-ESP32")
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, "config.h"), "#define VERSION 2")

          output = capture_stdout do
            Picotorokko::Commands::Device.start(["prepare"])
          end

          assert_match(/Applied patches/, output)

          # Verify patch applied
          build_path = Picotorokko::Env.get_build_path("20251124_150000")
          patched_file = File.join(build_path, "R2P2-ESP32", "config.h")
          assert_equal "#define VERSION 2", File.read(patched_file)
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
              Picotorokko::Commands::Device.start(["prepare"])
            end
          end

          assert_match(/No current environment set/, error.message)
        end
      end
    end
  end
end
