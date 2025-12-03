require_relative "../../test_helper"
require_relative "../../../lib/picotorokko/env"

module Picotorokko
  class EnvErrorsTest < Test::Unit::TestCase
    # Test error propagation in fetch_remote_default_branch
    sub_test_case "fetch_remote_default_branch error cases" do
      test "raises error when git command fails" do
        executor = MockExecutor.new
        # Simulate git command failure (non-zero exit code)
        executor.set_result(
          "git ls-remote --symref https://github.com/test/repo.git HEAD",
          fail: true,
          stderr: "fatal: repository not found"
        )

        Picotorokko::Env.set_executor(executor)

        error = assert_raise(RuntimeError) do
          Picotorokko::Env.fetch_remote_default_branch("https://github.com/test/repo.git")
        end

        assert_include error.message, "Command failed"
      end

      test "returns nil when git output is empty" do
        executor = MockExecutor.new
        executor.set_result(
          "git ls-remote --symref https://github.com/test/repo.git HEAD",
          stdout: "",
          stderr: ""
        )

        Picotorokko::Env.set_executor(executor)

        result = Picotorokko::Env.fetch_remote_default_branch("https://github.com/test/repo.git")
        assert_nil result
      end

      test "returns nil when output doesn't contain ref line" do
        executor = MockExecutor.new
        executor.set_result(
          "git ls-remote --symref https://github.com/test/repo.git HEAD",
          stdout: "abc123\tHEAD\n",
          stderr: ""
        )

        Picotorokko::Env.set_executor(executor)

        result = Picotorokko::Env.fetch_remote_default_branch("https://github.com/test/repo.git")
        assert_nil result
      end

      test "extracts branch name from valid output" do
        executor = MockExecutor.new
        executor.set_result(
          "git ls-remote --symref https://github.com/test/repo.git HEAD",
          stdout: "ref: refs/heads/main\tabc123\n",
          stderr: ""
        )

        Picotorokko::Env.set_executor(executor)

        result = Picotorokko::Env.fetch_remote_default_branch("https://github.com/test/repo.git")
        assert_equal "main", result
      end
    end

    # Test error handling in detect_openssl_flags
    sub_test_case "detect_openssl_flags error cases" do
      test "gracefully returns empty string when brew command fails" do
        executor = MockExecutor.new
        executor.set_result(
          "brew --prefix openssl@3",
          fail: true,
          stderr: "Error: brew not found"
        )

        Picotorokko::Env.set_executor(executor)

        result = Picotorokko::Env.detect_openssl_flags
        assert_equal "", result
      end

      test "returns empty string when openssl not installed" do
        executor = MockExecutor.new
        executor.set_result(
          "brew --prefix openssl@3",
          stdout: "",
          stderr: ""
        )

        Picotorokko::Env.set_executor(executor)

        result = Picotorokko::Env.detect_openssl_flags
        assert_equal "", result
      end

      test "returns valid export flags when openssl is installed" do
        executor = MockExecutor.new
        executor.set_result(
          "brew --prefix openssl@3",
          stdout: "/usr/local/opt/openssl@3\n",
          stderr: ""
        )

        Picotorokko::Env.set_executor(executor)

        result = Picotorokko::Env.detect_openssl_flags
        assert_include result, "export LDFLAGS"
        assert_include result, "/usr/local/opt/openssl@3/lib"
      end
    end

    # Test validate_env_name! error cases
    sub_test_case "validate_env_name! error cases" do
      test "raises error for invalid environment name format" do
        error = assert_raise(RuntimeError) do
          Picotorokko::Env.validate_env_name!("invalid-name")
        end

        assert_include error.message, "Invalid environment name"
        assert_include error.message, "invalid-name"
      end

      test "raises error for missing underscore" do
        error = assert_raise(RuntimeError) do
          Picotorokko::Env.validate_env_name!("20251121060114")
        end

        assert_include error.message, "Invalid environment name"
      end

      test "accepts valid environment name format" do
        # Should not raise
        assert_nothing_raised do
          Picotorokko::Env.validate_env_name!("20251121_060114")
        end
      end
    end
  end
end
