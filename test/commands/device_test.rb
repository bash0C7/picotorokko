# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsDeviceTest < Test::Unit::TestCase
  # テスト用の一時ディレクトリ
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    # 各テスト前にENV_FILEとBUILD_DIRをクリーンアップ
    FileUtils.rm_f(Pra::Env::ENV_FILE) if File.exist?(Pra::Env::ENV_FILE)
    FileUtils.rm_rf(Pra::Env::BUILD_DIR) if Dir.exist?(Pra::Env::BUILD_DIR)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  # device flash コマンドのテスト
  sub_test_case "device flash command" do
    test "raises error when environment not found" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pra::Commands::Device.start(['flash', 'nonexistent-env'])
        end
      end
    end

    test "raises error when no current environment is set" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pra::Commands::Device.start(['flash'])
        end
      end
    end

    test "raises error when build environment not found" do
      # テスト用の環境定義を作成するが、ビルド環境は作成しない
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      assert_raise(RuntimeError) do
        capture_stdout do
          Pra::Commands::Device.start(['flash', 'test-env'])
        end
      end
    end

    test "shows message when flashing" do
      # テスト用の環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      # ビルド環境を作成
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pra::Env.get_build_path(env_hash)
      r2p2_path = File.join(build_path, 'R2P2-ESP32')
      FileUtils.mkdir_p(r2p2_path)

      # execute_with_esp_env をスタブ化
      original_method = Pra::Env.method(:execute_with_esp_env)
      Pra::Env.define_singleton_method(:execute_with_esp_env) do |_cmd, _path|
        # スタブ：実際の実行は避ける
      end

      begin
        output = capture_stdout do
          Pra::Commands::Device.start(['flash', 'test-env'])
        end

        # 出力を確認
        assert_match(/Flashing: test-env/, output)
        assert_match(/✓ Flash completed/, output)
      ensure
        Pra::Env.define_singleton_method(:execute_with_esp_env, original_method)
      end
    end
  end

  # device monitor コマンドのテスト
  sub_test_case "device monitor command" do
    test "raises error when environment not found" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pra::Commands::Device.start(['monitor', 'nonexistent-env'])
        end
      end
    end

    test "raises error when no current environment is set" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pra::Commands::Device.start(['monitor'])
        end
      end
    end

    test "shows message when monitoring" do
      # テスト用の環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      # ビルド環境を作成
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pra::Env.get_build_path(env_hash)
      r2p2_path = File.join(build_path, 'R2P2-ESP32')
      FileUtils.mkdir_p(r2p2_path)

      # execute_with_esp_env をスタブ化
      original_method = Pra::Env.method(:execute_with_esp_env)
      Pra::Env.define_singleton_method(:execute_with_esp_env) do |_cmd, _path|
        # スタブ：実際の実行は避ける
      end

      begin
        output = capture_stdout do
          Pra::Commands::Device.start(['monitor', 'test-env'])
        end

        # 出力を確認
        assert_match(/Monitoring: test-env/, output)
        assert_match(/Press Ctrl\+C to exit/, output)
      ensure
        Pra::Env.define_singleton_method(:execute_with_esp_env, original_method)
      end
    end
  end

  # device build コマンドのテスト
  sub_test_case "device build command" do
    test "raises error when environment not found" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pra::Commands::Device.start(['build', 'nonexistent-env'])
        end
      end
    end

    test "shows message when building" do
      # テスト用の環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      # ビルド環境を作成
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pra::Env.get_build_path(env_hash)
      r2p2_path = File.join(build_path, 'R2P2-ESP32')
      FileUtils.mkdir_p(r2p2_path)

      # execute_with_esp_env をスタブ化
      original_method = Pra::Env.method(:execute_with_esp_env)
      Pra::Env.define_singleton_method(:execute_with_esp_env) do |_cmd, _path|
        # スタブ：実際の実行は避ける
      end

      begin
        output = capture_stdout do
          Pra::Commands::Device.start(['build', 'test-env'])
        end

        # 出力を確認
        assert_match(/Building: test-env/, output)
        assert_match(/✓ Build completed/, output)
      ensure
        Pra::Env.define_singleton_method(:execute_with_esp_env, original_method)
      end
    end
  end

  # device setup_esp32 コマンドのテスト
  sub_test_case "device setup_esp32 command" do
    test "raises error when environment not found" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pra::Commands::Device.start(['setup_esp32', 'nonexistent-env'])
        end
      end
    end

    test "shows message when setting up ESP32" do
      # テスト用の環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      # ビルド環境を作成
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pra::Env.get_build_path(env_hash)
      r2p2_path = File.join(build_path, 'R2P2-ESP32')
      FileUtils.mkdir_p(r2p2_path)

      # execute_with_esp_env をスタブ化
      original_method = Pra::Env.method(:execute_with_esp_env)
      Pra::Env.define_singleton_method(:execute_with_esp_env) do |_cmd, _path|
        # スタブ：実際の実行は避ける
      end

      begin
        output = capture_stdout do
          Pra::Commands::Device.start(['setup_esp32', 'test-env'])
        end

        # 出力を確認
        assert_match(/Setting up ESP32: test-env/, output)
        assert_match(/✓ ESP32 setup completed/, output)
      ensure
        Pra::Env.define_singleton_method(:execute_with_esp_env, original_method)
      end
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
