require_relative "../test_helper"
require_relative "../../lib/pra/executor"

module Pra
  class ExecutorTest < Test::Unit::TestCase
    # ProductionExecutor: 成功
    sub_test_case "ProductionExecutor" do
      test "execute successful command" do
        executor = ProductionExecutor.new
        stdout, stderr = executor.execute('echo "hello"')

        assert_includes stdout, "hello"
        assert_empty stderr
      end

      test "execute command with stderr" do
        executor = ProductionExecutor.new
        _, stderr = executor.execute('ruby -e "STDERR.puts \"error message\""')

        assert_includes stderr, "error message"
      end

      test "raise RuntimeError on failed command" do
        executor = ProductionExecutor.new
        error = assert_raise(RuntimeError) { executor.execute("exit 1") }

        assert_include error.message, "Command failed"
        assert_include error.message, "exit 1"
      end

      test "execute command with working_dir" do
        executor = ProductionExecutor.new
        Dir.mktmpdir do |tmpdir|
          test_file = File.join(tmpdir, "test.txt")
          File.write(test_file, "content")

          stdout, _stderr = executor.execute("ls test.txt", tmpdir)
          assert_include stdout, "test.txt"
        end
      end

      test "raise error with command and stderr details on failure" do
        executor = ProductionExecutor.new
        error = assert_raise(RuntimeError) do
          executor.execute('ruby -e "STDERR.puts \"bad error\"; exit 5"')
        end

        assert_include error.message, "exit 5"
        assert_include error.message, "bad error"
      end
    end

    # MockExecutor: テスト用
    sub_test_case "MockExecutor" do
      test "record executed commands" do
        executor = MockExecutor.new
        executor.execute("echo test")
        executor.execute("ls -la")

        assert_equal 2, executor.calls.length
        assert_equal "echo test", executor.calls[0][:command]
        assert_equal "ls -la", executor.calls[1][:command]
      end

      test "return default success result" do
        executor = MockExecutor.new
        stdout, stderr = executor.execute("any command")

        assert_empty stdout
        assert_empty stderr
      end

      test "return preset result" do
        executor = MockExecutor.new
        executor.set_result("git log", stdout: "commit abc123", stderr: "")

        stdout, stderr = executor.execute("git log")

        assert_equal "commit abc123", stdout
        assert_empty stderr
      end

      test "raise error on preset failure" do
        executor = MockExecutor.new
        executor.set_result("git clone url dest", fail: true, stderr: "fatal: repo not found")

        error = assert_raise(RuntimeError) do
          executor.execute("git clone url dest")
        end

        assert_include error.message, "fatal: repo not found"
      end

      test "record working_dir in calls" do
        executor = MockExecutor.new
        executor.execute("pwd", "/tmp")

        assert_equal "/tmp", executor.calls[0][:working_dir]
      end

      test "execute command with working_dir" do
        executor = MockExecutor.new
        Dir.mktmpdir do |tmpdir|
          # mock はディレクトリ変更をしないが、呼び出し記録に出現する
          executor.execute("pwd", tmpdir)

          assert_equal tmpdir, executor.calls[0][:working_dir]
        end
      end
    end
  end
end
