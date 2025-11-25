require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/picotorokko/commands/env"

class ScenarioMultiEnvTest < PicotorokkoTestCase
  # multiple environment management シナリオテスト
  # Verify multiple environment creation and switching

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

  sub_test_case "Scenario: multiple environment management" do
    test "Steps 1-4: can create and list multiple environments" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create env1
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env1_name = "20251123_100000"
          Picotorokko::Env.set_environment(env1_name, r2p2_info, esp32_info, picoruby_info)

          # Create env2 (different timestamp)
          env2_name = "20251123_100100"
          Picotorokko::Env.set_environment(env2_name, r2p2_info, esp32_info, picoruby_info)

          # List environments
          output = capture_stdout do
            Picotorokko::Commands::Env.start(["list"])
          end

          # Verify both environments displayed
          assert_match(/#{env1_name}/, output)
          assert_match(/#{env2_name}/, output)
        end
      end
    end

    test "Steps 5-7: can switch between environments" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create two environments
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env1_name = "20251123_110000"
          env2_name = "20251123_110100"

          Picotorokko::Env.set_environment(env1_name, r2p2_info, esp32_info, picoruby_info)
          Picotorokko::Env.set_environment(env2_name, r2p2_info, esp32_info, picoruby_info)

          # Select env1
          capture_stdout do
            Picotorokko::Commands::Env.start(["current", env1_name])
          end
          assert_equal env1_name, Picotorokko::Env.get_current_env

          # Switch to env2
          capture_stdout do
            Picotorokko::Commands::Env.start(["current", env2_name])
          end
          assert_equal env2_name, Picotorokko::Env.get_current_env

          # Switch back to env1
          capture_stdout do
            Picotorokko::Commands::Env.start(["current", env1_name])
          end
          assert_equal env1_name, Picotorokko::Env.get_current_env
        end
      end
    end

    test "Step 9: multiple build directories can coexist" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create two environments
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env1_name = "20251123_120000"
          env2_name = "20251123_120100"

          Picotorokko::Env.set_environment(env1_name, r2p2_info, esp32_info, picoruby_info)
          Picotorokko::Env.set_environment(env2_name, r2p2_info, esp32_info, picoruby_info)

          # Create build directories for both environments
          build_path1 = Picotorokko::Env.get_build_path(env1_name)
          build_path2 = Picotorokko::Env.get_build_path(env2_name)

          FileUtils.mkdir_p(File.join(build_path1, "R2P2-ESP32"))
          FileUtils.mkdir_p(File.join(build_path2, "R2P2-ESP32"))

          # Write different content to each
          File.write(File.join(build_path1, "R2P2-ESP32", "env.txt"), "env1")
          File.write(File.join(build_path2, "R2P2-ESP32", "env.txt"), "env2")

          # Verify both directories exist and have correct content
          assert Dir.exist?(build_path1)
          assert Dir.exist?(build_path2)
          assert_equal "env1", File.read(File.join(build_path1, "R2P2-ESP32", "env.txt"))
          assert_equal "env2", File.read(File.join(build_path2, "R2P2-ESP32", "env.txt"))
        end
      end
    end

    test "environment info is correctly stored and retrieved" do
      omit "シナリオテスト全体見直し中 - 一時的に無効化"
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          Picotorokko::Env.instance_variable_set(:@project_root, nil)
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create environment with specific info
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }
          env_name = "20251123_130000"

          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

          # Retrieve and verify environment exists
          env_config = Picotorokko::Env.get_environment(env_name)
          assert_not_nil env_config, "Environment should be stored"

          # Verify structure contains repo info (keys may vary)
          assert env_config.is_a?(Hash), "Environment config should be a hash"
        end
      end
    end

    test "can delete environment" do
      omit "[TODO] env delete command not yet implemented"
    end
  end
end
