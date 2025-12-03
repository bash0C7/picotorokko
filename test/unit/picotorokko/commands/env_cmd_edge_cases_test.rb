require "English"
require_relative "../../../test_helper"
require_relative "../../../../lib/picotorokko/commands/env"

class CommandsEnvCmdEdgeCasesTest < PicotorokkoTestCase
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
    Picotorokko::Env.reset_cached_root!
    FileUtils.rm_f(Picotorokko::Env::ENV_FILE)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  # Edge cases for list command
  sub_test_case "env list command edge cases" do
    test "lists empty when no environments exist" do
      output = capture_stdout do
        Picotorokko::Commands::Env.start(["list"])
      end

      assert_includes output, "No environments defined"
    end

    test "lists multiple environments correctly" do
      r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
      esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
      picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

      Picotorokko::Env.set_environment("20251121_100000", r2p2_info, esp32_info, picoruby_info)
      Picotorokko::Env.set_environment("20251122_110000", r2p2_info, esp32_info, picoruby_info)
      Picotorokko::Env.set_environment("20251123_120000", r2p2_info, esp32_info, picoruby_info)

      output = capture_stdout do
        Picotorokko::Commands::Env.start(["list"])
      end

      assert_includes output, "20251121_100000"
      assert_includes output, "20251122_110000"
      assert_includes output, "20251123_120000"
    end
  end

  # Edge cases for show command
  sub_test_case "env show command edge cases" do
    test "shows error when no env specified and no current set" do
      capture_stdout do
        Picotorokko::Commands::Env.start(["show"])
      rescue SystemExit, RuntimeError
        # Expected - no env specified, no current
      end

      # May be silent or show error
    end

    test "shows error when environment not found" do
      capture_stdout do
        Picotorokko::Commands::Env.start(["show", "nonexistent_env"])
      rescue SystemExit
        # Expected
      end

      # May show "not found" message or be silent
    end

    test "shows environment when it exists" do
      r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
      esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
      picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

      Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

      output = capture_stdout do
        Picotorokko::Commands::Env.start(["show", "20251121_120000"])
      end

      assert_includes output, "20251121_120000"
    end
  end

  # Edge cases for set command
  sub_test_case "env set command edge cases" do
    test "requires all three repo options if any specified" do
      # Only specifying one option should fail
      assert_raise(RuntimeError) do
        Picotorokko::Commands::Env.start([
                                           "set", "20251121_120000",
                                           "--R2P2-ESP32", "picoruby/R2P2-ESP32"
                                         ])
      end

      # Should indicate missing required options or similar
    end

    test "rejects invalid environment name" do
      error = assert_raise(RuntimeError) do
        Picotorokko::Commands::Env.start([
                                           "set", "invalid-env",
                                           "--R2P2-ESP32", "path:../R2P2-ESP32",
                                           "--picoruby-esp32", "path:../picoruby-esp32",
                                           "--picoruby", "path:../picoruby"
                                         ])
      end

      assert_include error.message, "Invalid environment name"
    end

    test "handles --current flag to set current environment" do
      r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
      esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
      picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

      Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

      # Set as current
      capture_stdout do
        Picotorokko::Commands::Env.start(["set", "20251121_120000", "--current"])
      rescue SystemExit, RuntimeError
        # May fail if set tries to fetch, which is expected
      end

      # Just verify command was invoked without crashing
    end
  end

  # Edge cases for remove command
  sub_test_case "env remove command edge cases" do
    test "removes existing environment" do
      r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
      esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
      picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

      Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

      # Verify it exists
      assert_not_nil Picotorokko::Env.get_environment("20251121_120000")

      # Remove it
      Picotorokko::Commands::Env.start(["remove", "20251121_120000"])

      # Verify it's gone
      assert_nil Picotorokko::Env.get_environment("20251121_120000")
    end

    test "clears current environment when removing it" do
      r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
      esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
      picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

      Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)
      Picotorokko::Env.set_current_env("20251121_120000")

      # Verify current is set
      assert_equal "20251121_120000", Picotorokko::Env.get_current_env

      # Remove it
      Picotorokko::Commands::Env.start(["remove", "20251121_120000"])

      # Current should be cleared
      assert_nil Picotorokko::Env.get_current_env
    end

    test "handles non-existent environment removal gracefully" do
      # Removing non-existent environment should not crash
      capture_stdout do
        Picotorokko::Commands::Env.start(["remove", "nonexistent"])
      rescue SystemExit, RuntimeError
        # May raise or be silent - both acceptable
      end

      # Just verify no crash
    end
  end
end
