require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsCiTest < Test::Unit::TestCase
  # テスト用の一時ディレクトリ
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
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

  # 標準入力をモックするヘルパー
  def with_stdin(input)
    original_stdin = $stdin
    $stdin = StringIO.new(input)
    yield
  ensure
    $stdin = original_stdin
  end

  # ci setup コマンドのテスト
  sub_test_case "ci setup command" do
    test "creates workflow directory and copies template file" do
      output = capture_stdout do
        Pra::Commands::Ci.start(['setup'])
      end

      # 出力を確認
      assert_match(/Setting up GitHub Actions workflow/, output)
      assert_match(/Created directory: \.github\/workflows/, output)
      assert_match(/Copied workflow file/, output)
      assert_match(/Setup Complete/, output)

      # ディレクトリが作成されたことを確認
      assert_true(Dir.exist?('.github/workflows'))

      # ファイルがコピーされたことを確認
      target_file = File.join('.github', 'workflows', 'esp32-build.yml')
      assert_true(File.exist?(target_file))

      # ファイル内容を確認（少なくともYAMLヘッダーがあることを確認）
      content = File.read(target_file)
      assert_match(/name:/, content)
      assert_match(/on:/, content)
    end

    test "prompts for overwrite when file already exists and user declines" do
      # 既存ファイルを作成
      FileUtils.mkdir_p('.github/workflows')
      existing_file = File.join('.github', 'workflows', 'esp32-build.yml')
      File.write(existing_file, "existing content")

      output = capture_stdout do
        with_stdin("n\n") do
          Pra::Commands::Ci.start(['setup'])
        end
      end

      # 出力を確認
      assert_match(/File already exists/, output)
      assert_match(/Cancelled/, output)

      # ファイルが上書きされていないことを確認
      content = File.read(existing_file)
      assert_equal("existing content", content)
    end

    test "overwrites file when user confirms" do
      # 既存ファイルを作成
      FileUtils.mkdir_p('.github/workflows')
      existing_file = File.join('.github', 'workflows', 'esp32-build.yml')
      File.write(existing_file, "existing content")

      output = capture_stdout do
        with_stdin("y\n") do
          Pra::Commands::Ci.start(['setup'])
        end
      end

      # 出力を確認
      assert_match(/File already exists/, output)
      assert_match(/Copied workflow file/, output)
      assert_match(/Setup Complete/, output)

      # ファイルが上書きされたことを確認
      content = File.read(existing_file)
      assert_not_equal("existing content", content)
      assert_match(/name:/, content)
    end

    test "accepts 'yes' as full word for confirmation" do
      # 既存ファイルを作成
      FileUtils.mkdir_p('.github/workflows')
      existing_file = File.join('.github', 'workflows', 'esp32-build.yml')
      File.write(existing_file, "existing content")

      output = capture_stdout do
        with_stdin("yes\n") do
          Pra::Commands::Ci.start(['setup'])
        end
      end

      # 出力を確認
      assert_match(/Setup Complete/, output)

      # ファイルが上書きされたことを確認
      content = File.read(existing_file)
      assert_match(/name:/, content)
    end
  end
end
