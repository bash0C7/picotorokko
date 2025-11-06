# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PapCommandsBuildTest < Test::Unit::TestCase
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

  # build list コマンドのテスト
  sub_test_case "build list command" do
    test "shows 'No build environments found' when build directory is empty" do
      output = capture_stdout do
        Pap::Commands::Build.start(['list'])
      end

      assert_match(/=== Build Environments ===/, output)
      assert_match(/Current: \(not set\)/, output)
      assert_match(/No build environments found/, output)
    end

    test "lists build environments when they exist" do
      # テスト用のビルド環境を作成
      FileUtils.mkdir_p(Pap::Env::BUILD_DIR)
      FileUtils.mkdir_p(File.join(Pap::Env::BUILD_DIR, 'env1-hash'))
      FileUtils.mkdir_p(File.join(Pap::Env::BUILD_DIR, 'env2-hash'))

      output = capture_stdout do
        Pap::Commands::Build.start(['list'])
      end

      assert_match(/=== Build Environments ===/, output)
      assert_match(/Available:/, output)
      assert_match(/env1-hash/, output)
      assert_match(/env2-hash/, output)
    end

    test "shows current symlink when it exists" do
      # ビルド環境とシンボリックリンクを作成
      FileUtils.mkdir_p(Pap::Env::BUILD_DIR)
      target_dir = 'test-env-hash'
      FileUtils.mkdir_p(File.join(Pap::Env::BUILD_DIR, target_dir))

      current_link = File.join(Pap::Env::BUILD_DIR, 'current')
      FileUtils.ln_s(target_dir, current_link)

      output = capture_stdout do
        Pap::Commands::Build.start(['list'])
      end

      assert_match(/=== Build Environments ===/, output)
      assert_match(/Current: build\/current -> #{Regexp.escape(target_dir)}/, output)
      assert_match(/#{Regexp.escape(target_dir)}/, output)
    end
  end

  # build clean コマンドのテスト
  sub_test_case "build clean command" do
    test "shows error when no environment is configured" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pap::Commands::Build.start(['clean', 'non-existent'])
        end
      end
    end

    test "shows message when build directory does not exist" do
      # 環境定義を作成するが、ビルドディレクトリは作成しない
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

      Pap::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      output = capture_stdout do
        Pap::Commands::Build.start(['clean', 'test-env'])
      end

      assert_match(/Build environment not found/, output)
    end

    test "removes build directory when it exists" do
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

      assert_true(Dir.exist?(build_path))

      output = capture_stdout do
        Pap::Commands::Build.start(['clean', 'test-env'])
      end

      assert_match(/Removing build environment/, output)
      assert_match(/✓ Build environment removed/, output)
      assert_false(Dir.exist?(build_path))
    end

    test "removes current symlink when cleaning with 'current' argument" do
      # 環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

      Pap::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)
      Pap::Env.set_current_env('test-env')

      # ビルドディレクトリとシンボリックリンクを作成
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pap::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pap::Env.get_build_path(env_hash)
      FileUtils.mkdir_p(build_path)

      current_link = File.join(Pap::Env::BUILD_DIR, 'current')
      FileUtils.ln_s(env_hash, current_link)

      assert_true(File.symlink?(current_link))

      output = capture_stdout do
        Pap::Commands::Build.start(['clean', 'current'])
      end

      assert_match(/✓ Current build environment removed/, output)
      assert_false(File.exist?(current_link))
      assert_false(Dir.exist?(build_path))
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
