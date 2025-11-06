# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PapCommandsCacheTest < Test::Unit::TestCase
  # テスト用の一時ディレクトリ
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    # 各テスト前にENV_FILEとCACHE_DIRをクリーンアップ
    FileUtils.rm_f(Pap::Env::ENV_FILE) if File.exist?(Pap::Env::ENV_FILE)
    FileUtils.rm_rf(Pap::Env::CACHE_DIR) if Dir.exist?(Pap::Env::CACHE_DIR)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  # cache list コマンドのテスト
  sub_test_case "cache list command" do
    test "shows '(no cache)' when cache directory is empty" do
      output = capture_stdout do
        Pap::Commands::Cache.start(['list'])
      end

      assert_match(/R2P2-ESP32: \(no cache\)/, output)
      assert_match(/picoruby-esp32: \(no cache\)/, output)
      assert_match(/picoruby: \(no cache\)/, output)
    end

    test "lists cached repositories when cache exists" do
      # テスト用のキャッシュディレクトリを作成
      FileUtils.mkdir_p(File.join(Pap::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000'))
      FileUtils.mkdir_p(File.join(Pap::Env::CACHE_DIR, 'R2P2-ESP32', 'def5678-20250102_120000'))
      FileUtils.mkdir_p(File.join(Pap::Env::CACHE_DIR, 'picoruby-esp32', 'ghi9012-20250103_120000'))

      output = capture_stdout do
        Pap::Commands::Cache.start(['list'])
      end

      assert_match(/R2P2-ESP32:/, output)
      assert_match(/abc1234-20250101_120000/, output)
      assert_match(/def5678-20250102_120000/, output)
      assert_match(/picoruby-esp32:/, output)
      assert_match(/ghi9012-20250103_120000/, output)
      assert_match(/picoruby: \(no cache\)/, output)
    end
  end

  # cache clean コマンドのテスト
  sub_test_case "cache clean command" do
    test "shows message when cache does not exist" do
      output = capture_stdout do
        Pap::Commands::Cache.start(['clean', 'R2P2-ESP32'])
      end

      assert_match(/Cache not found/, output)
    end

    test "removes cache when it exists" do
      # テスト用のキャッシュディレクトリを作成
      cache_path = File.join(Pap::Env::CACHE_DIR, 'R2P2-ESP32')
      FileUtils.mkdir_p(File.join(cache_path, 'abc1234-20250101_120000'))
      FileUtils.mkdir_p(File.join(cache_path, 'def5678-20250102_120000'))

      assert_true(Dir.exist?(cache_path))

      output = capture_stdout do
        Pap::Commands::Cache.start(['clean', 'R2P2-ESP32'])
      end

      assert_match(/Removing cache/, output)
      assert_match(/✓ Cache cleaned/, output)
      assert_false(Dir.exist?(cache_path))
    end
  end

  # cache prune コマンドのテスト
  sub_test_case "cache prune command" do
    test "removes unused caches and keeps referenced caches" do
      # テスト用の環境を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

      Pap::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      # テスト用のキャッシュディレクトリを作成（使用中と未使用の両方）
      FileUtils.mkdir_p(File.join(Pap::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000'))  # 使用中
      FileUtils.mkdir_p(File.join(Pap::Env::CACHE_DIR, 'R2P2-ESP32', 'unused1-20240101_120000'))  # 未使用
      FileUtils.mkdir_p(File.join(Pap::Env::CACHE_DIR, 'picoruby-esp32', 'def5678-20250102_120000'))  # 使用中
      FileUtils.mkdir_p(File.join(Pap::Env::CACHE_DIR, 'picoruby', 'ghi9012-20250103_120000'))  # 使用中
      FileUtils.mkdir_p(File.join(Pap::Env::CACHE_DIR, 'picoruby', 'unused2-20240101_120000'))  # 未使用

      output = capture_stdout do
        Pap::Commands::Cache.start(['prune'])
      end

      assert_match(/Keep: R2P2-ESP32\/abc1234-20250101_120000/, output)
      assert_match(/Remove: R2P2-ESP32\/unused1-20240101_120000/, output)
      assert_match(/Keep: picoruby-esp32\/def5678-20250102_120000/, output)
      assert_match(/Keep: picoruby\/ghi9012-20250103_120000/, output)
      assert_match(/Remove: picoruby\/unused2-20240101_120000/, output)
      assert_match(/✓ Pruning completed/, output)

      # 使用中のキャッシュは残っている
      assert_true(Dir.exist?(File.join(Pap::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000')))
      assert_true(Dir.exist?(File.join(Pap::Env::CACHE_DIR, 'picoruby-esp32', 'def5678-20250102_120000')))
      assert_true(Dir.exist?(File.join(Pap::Env::CACHE_DIR, 'picoruby', 'ghi9012-20250103_120000')))

      # 未使用のキャッシュは削除されている
      assert_false(Dir.exist?(File.join(Pap::Env::CACHE_DIR, 'R2P2-ESP32', 'unused1-20240101_120000')))
      assert_false(Dir.exist?(File.join(Pap::Env::CACHE_DIR, 'picoruby', 'unused2-20240101_120000')))
    end

    test "handles empty cache directory gracefully" do
      output = capture_stdout do
        Pap::Commands::Cache.start(['prune'])
      end

      assert_match(/Pruning unused cache/, output)
      assert_match(/✓ Pruning completed/, output)
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
