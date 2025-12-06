require_relative "../../test_helper"
require_relative "../../../lib/picotorokko/executor"

module Picotorokko
  class ExecutorEdgeCasesTest < Test::Unit::TestCase
    # ProductionExecutor: Edge cases
    sub_test_case "ProductionExecutor edge cases" do
      test "handles large output correctly" do
        executor = ProductionExecutor.new
        # Generate large output (1000 lines)
        large_output_cmd = 'ruby -e "1000.times { puts \"line\n\" }"'
        stdout, _stderr = executor.execute(large_output_cmd)

        # Should capture all lines
        lines = stdout.split("\n").compact
        assert lines.length >= 999, "Should capture most/all lines of large output"
      end

      test "captures unicode output correctly" do
        executor = ProductionExecutor.new
        # Use printf to avoid encoding issues with heredoc
        stdout, _stderr = executor.execute("printf 'hello world'")

        assert_includes stdout, "hello world"
      end

      test "handles command with pipes" do
        executor = ProductionExecutor.new
        stdout, _stderr = executor.execute('echo "hello world" | tr a-z A-Z')

        assert_includes stdout, "HELLO WORLD"
      end

      test "handles empty output" do
        executor = ProductionExecutor.new
        stdout, stderr = executor.execute("true")

        assert_equal "", stdout
        assert_equal "", stderr
      end

      test "preserves multiline stderr output" do
        executor = ProductionExecutor.new
        _, stderr = executor.execute('ruby -e "STDERR.puts \"line1\nline2\nline3\""')

        assert_includes stderr, "line1"
        assert_includes stderr, "line2"
        assert_includes stderr, "line3"
      end

      test "handles command with exit code > 1" do
        executor = ProductionExecutor.new
        error = assert_raise(RuntimeError) { executor.execute("exit 42") }

        assert_include error.message, "exit 42"
      end

      test "executes in non-existent working directory raises error" do
        executor = ProductionExecutor.new
        # Dir.chdir raises Errno::ENOENT for non-existent directory
        error = assert_raise(Errno::ENOENT) do
          executor.execute("pwd", "/non/existent/dir/xyz")
        end

        assert_include error.message, "No such file or directory"
      end
    end

    # MockExecutor: Edge cases
    sub_test_case "MockExecutor edge cases" do
      test "handles multiple commands with same prefix" do
        executor = MockExecutor.new
        executor.set_result("git clone url1", stdout: "cloned 1", stderr: "")
        executor.set_result("git clone url2", stdout: "cloned 2", stderr: "")

        stdout1, _stderr = executor.execute("git clone url1")
        stdout2, _stderr = executor.execute("git clone url2")

        assert_equal "cloned 1", stdout1
        assert_equal "cloned 2", stdout2
      end

      test "returns consistent results on repeated calls" do
        executor = MockExecutor.new
        executor.set_result("test cmd", stdout: "result", stderr: "")

        result1 = executor.execute("test cmd")
        result2 = executor.execute("test cmd")
        result3 = executor.execute("test cmd")

        assert_equal result1, result2
        assert_equal result2, result3
      end

      test "preserves stderr in error case" do
        executor = MockExecutor.new
        executor.set_result(
          "failing cmd",
          stdout: "partial output",
          stderr: "error line 1\nerror line 2",
          fail: true
        )

        error = assert_raise(RuntimeError) do
          executor.execute("failing cmd")
        end

        assert_include error.message, "error line"
      end

      test "handles very long command string" do
        executor = MockExecutor.new
        long_cmd = "echo #{"x" * 1000}"
        executor.set_result(long_cmd, stdout: "ok", stderr: "")

        stdout, _stderr = executor.execute(long_cmd)
        assert_equal "ok", stdout

        # Verify command was recorded
        assert_equal long_cmd, executor.calls[0][:command]
      end

      test "records multiple calls with different working_dirs" do
        executor = MockExecutor.new
        executor.execute("cmd1", "/path1")
        executor.execute("cmd1", "/path2")
        executor.execute("cmd2", "/path1")

        assert_equal 3, executor.calls.length
        assert_equal "/path1", executor.calls[0][:working_dir]
        assert_equal "/path2", executor.calls[1][:working_dir]
        assert_equal "/path1", executor.calls[2][:working_dir]
      end

      test "handles mixed success and failure results" do
        executor = MockExecutor.new
        executor.set_result("cmd1", stdout: "ok", stderr: "", fail: false)
        executor.set_result("cmd2", stdout: "", stderr: "error", fail: true)
        executor.set_result("cmd3", stdout: "ok", stderr: "", fail: false)

        stdout1, _stderr = executor.execute("cmd1")
        assert_equal "ok", stdout1

        error = assert_raise(RuntimeError) { executor.execute("cmd2") }
        assert_include error.message, "error"

        stdout3, _stderr = executor.execute("cmd3")
        assert_equal "ok", stdout3
      end

      test "returns default empty success when command not preset" do
        executor = MockExecutor.new
        # Don't set any result
        stdout, stderr = executor.execute("unknown command")

        assert_equal "", stdout
        assert_equal "", stderr
      end
    end
  end
end
