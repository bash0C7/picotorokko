require "test_helper"
require "stringio"

class PraTest < Test::Unit::TestCase
  # VERSION定数の存在確認
  test "VERSION constant is defined" do
    assert do
      ::Pra.const_defined?(:VERSION)
    end
  end

  # CLI: versionコマンドの出力テスト
  sub_test_case "CLI version command" do
    test "outputs version string" do
      # 標準出力をキャプチャ
      output = capture_stdout do
        Pra::CLI.start(['version'])
      end

      # バージョン情報が出力されることを確認
      assert_match(/pra version \d+\.\d+\.\d+/, output)
      assert_match(/#{Pra::VERSION}/, output)
    end

    test "outputs version with --version flag" do
      output = capture_stdout do
        Pra::CLI.start(['--version'])
      end

      assert_match(/pra version #{Pra::VERSION}/, output)
    end

    test "outputs version with -v flag" do
      output = capture_stdout do
        Pra::CLI.start(['-v'])
      end

      assert_match(/pra version #{Pra::VERSION}/, output)
    end
  end

  private

  # 標準出力をキャプチャするヘルパーメソッド
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
