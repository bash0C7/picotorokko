# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PapCommandsEnvTest < Test::Unit::TestCase
  # テスト用の一時ディレクトリ
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    # 各テスト前にENV_FILEとBUILD_DIRをクリーンアップ
    FileUtils.rm_f(Pap::Env::ENV_FILE) if File.exist?(Pap::Env::ENV_FILE)
    FileUtils.rm_rf(Pap::Env::BUILD_DIR) if Dir.exist?(Pap::Env::BUILD_DIR)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  # env show コマンドのテスト
  sub_test_case "env show command" do
    test "shows '(not set)' when no environment is configured" do
      output = capture_stdout do
        Pap::Commands::Env.start(['show'])
      end

      assert_match(/Current environment: \(not set\)/, output)
      assert_match(/Run 'pap env set ENV_NAME' to set an environment/, output)
    end

    test "shows error when environment is set but not found in config" do
      # current環境を設定するが、定義は作成しない
      Pap::Env.set_current_env('missing-env')

      output = capture_stdout do
        Pap::Commands::Env.start(['show'])
      end

      assert_match(/Error: Environment 'missing-env' not found/, output)
    end

    test "shows environment details when properly configured" do
      # テスト用の環境を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

      Pap::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info, notes: 'Test environment')
      Pap::Env.set_current_env('test-env')

      output = capture_stdout do
        Pap::Commands::Env.start(['show'])
      end

      assert_match(/Current environment: test-env/, output)
      assert_match(/Repo versions:/, output)
      assert_match(/R2P2-ESP32: abc1234 \(20250101_120000\)/, output)
      assert_match(/picoruby-esp32: def5678 \(20250102_120000\)/, output)
      assert_match(/picoruby: ghi9012 \(20250103_120000\)/, output)
      assert_match(/Notes: Test environment/, output)
    end

    test "shows symlink information when available" do
      # テスト用の環境とシンボリックリンクを作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

      Pap::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)
      Pap::Env.set_current_env('test-env')

      # BUILD_DIRとcurrentシンボリックリンクを作成（正しいenv_hashを使用）
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pap::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)

      FileUtils.mkdir_p(Pap::Env::BUILD_DIR)
      target = File.join(Pap::Env::BUILD_DIR, env_hash)
      FileUtils.mkdir_p(target)
      current_link = File.join(Pap::Env::BUILD_DIR, 'current')
      FileUtils.ln_s(env_hash, current_link)

      output = capture_stdout do
        Pap::Commands::Env.start(['show'])
      end

      assert_match(/Symlink: current -> #{Regexp.escape(env_hash)}\//, output)
    end
  end

  # env set コマンドのテスト
  sub_test_case "env set command" do
    test "raises error when environment does not exist" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pap::Commands::Env.start(['set', 'non-existent'])
        end
      end
    end

    test "shows error when build directory does not exist" do
      # 環境定義は作成するが、ビルドディレクトリは作成しない
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

      Pap::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      output = capture_stdout do
        Pap::Commands::Env.start(['set', 'test-env'])
      end

      assert_match(/Error: Build environment not found/, output)
      assert_match(/Run 'pap build setup test-env' first/, output)
    end

    test "successfully switches environment when build exists" do
      # 環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

      Pap::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      # ビルドディレクトリを作成
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pap::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pap::Env.get_build_path(env_hash)
      FileUtils.mkdir_p(build_path)

      output = capture_stdout do
        Pap::Commands::Env.start(['set', 'test-env'])
      end

      assert_match(/Switching to environment: test-env/, output)
      assert_match(/✓ Switched to test-env/, output)

      # currentが正しく設定されていることを確認
      assert_equal('test-env', Pap::Env.get_current_env)

      # シンボリックリンクが作成されていることを確認
      current_link = File.join(Pap::Env::BUILD_DIR, 'current')
      assert_true(File.symlink?(current_link))
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
