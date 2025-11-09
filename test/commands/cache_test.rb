require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsCacheTest < PraTestCase
  # cache fetch コマンドのテスト
  sub_test_case "cache fetch command" do
    test "fetches environment and caches repositories" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::CACHE_DIR)

          # テスト用の環境定義を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          # クローン処理をスタブ化（実際のgit cloneを避ける）
          original_method = Pra::Env.method(:clone_with_submodules)
          Pra::Env.define_singleton_method(:clone_with_submodules) do |url, path, commit|
            # テスト用にディレクトリだけ作成（git cloneの代わり）
            FileUtils.mkdir_p(path)
            # .git ディレクトリも作成して疑似 git リポジトリに見せる
            FileUtils.mkdir_p(File.join(path, '.git'))
          end

          # traverse_submodules_and_validate もスタブ化
          Pra::Env.define_singleton_method(:traverse_submodules_and_validate) do |_path|
            [[], []]  # info と warnings を返す
          end

          begin
            output = capture_stdout do
              Pra::Commands::Cache.start(['fetch', 'test-env'])
            end

            # 出力を確認
            assert_match(/Fetching environment: test-env/, output)
            assert_match(/✓ R2P2-ESP32 cached to/, output)
            assert_match(/✓ picoruby-esp32 cached to/, output)
            assert_match(/✓ picoruby cached to/, output)
            assert_match(/✓ Environment 'test-env' fetched successfully/, output)

            # キャッシュが作成されたことを確認
            r2p2_cache = File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000')
            esp32_cache = File.join(Pra::Env::CACHE_DIR, 'picoruby-esp32', 'def5678-20250102_120000')
            picoruby_cache = File.join(Pra::Env::CACHE_DIR, 'picoruby', 'ghi9012-20250103_120000')

            assert_true(Dir.exist?(r2p2_cache))
            assert_true(Dir.exist?(esp32_cache))
            assert_true(Dir.exist?(picoruby_cache))
          ensure
            # 元のメソッドを復元
            Pra::Env.define_singleton_method(:clone_with_submodules, original_method)
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "raises error when environment not found" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::CACHE_DIR)

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Cache.start(['fetch', 'nonexistent-env'])
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "skips cache fetch when already cached" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::CACHE_DIR)

          # テスト用の環境定義を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          # キャッシュディレクトリを事前に作成
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000'))
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'picoruby-esp32', 'def5678-20250102_120000'))
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'picoruby', 'ghi9012-20250103_120000'))

          # clone_with_submodules をスタブ化
          original_method = Pra::Env.method(:clone_with_submodules)
          Pra::Env.define_singleton_method(:clone_with_submodules) do |_url, _path, _commit|
            # 呼ばれないはず
            raise 'clone_with_submodules should not be called for already cached repos'
          end

          # traverse_submodules_and_validate もスタブ化
          Pra::Env.define_singleton_method(:traverse_submodules_and_validate) do |_path|
            [[], []]
          end

          begin
            output = capture_stdout do
              Pra::Commands::Cache.start(['fetch', 'test-env'])
            end

            # 出力を確認
            assert_match(/✓ R2P2-ESP32 already cached/, output)
            assert_match(/✓ picoruby-esp32 already cached/, output)
            assert_match(/✓ picoruby already cached/, output)
          ensure
            Pra::Env.define_singleton_method(:clone_with_submodules, original_method)
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # cache list コマンドのテスト
  sub_test_case "cache list command" do
    test "shows '(no cache)' when cache directory is empty" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::CACHE_DIR)

          output = capture_stdout do
            Pra::Commands::Cache.start(['list'])
          end

          assert_match(/R2P2-ESP32: \(no cache\)/, output)
          assert_match(/picoruby-esp32: \(no cache\)/, output)
          assert_match(/picoruby: \(no cache\)/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "lists cached repositories when cache exists" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::CACHE_DIR)

          # テスト用のキャッシュディレクトリを作成
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000'))
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'def5678-20250102_120000'))
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'picoruby-esp32', 'ghi9012-20250103_120000'))

          output = capture_stdout do
            Pra::Commands::Cache.start(['list'])
          end

          assert_match(/R2P2-ESP32:/, output)
          assert_match(/abc1234-20250101_120000/, output)
          assert_match(/def5678-20250102_120000/, output)
          assert_match(/picoruby-esp32:/, output)
          assert_match(/ghi9012-20250103_120000/, output)
          assert_match(/picoruby: \(no cache\)/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # cache clean コマンドのテスト
  sub_test_case "cache clean command" do
    test "shows message when cache does not exist" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::CACHE_DIR)

          output = capture_stdout do
            Pra::Commands::Cache.start(['clean', 'R2P2-ESP32'])
          end

          assert_match(/Cache not found/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "removes cache when it exists" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::CACHE_DIR)

          # テスト用のキャッシュディレクトリを作成
          cache_path = File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32')
          FileUtils.mkdir_p(File.join(cache_path, 'abc1234-20250101_120000'))
          FileUtils.mkdir_p(File.join(cache_path, 'def5678-20250102_120000'))

          assert_true(Dir.exist?(cache_path))

          output = capture_stdout do
            Pra::Commands::Cache.start(['clean', 'R2P2-ESP32'])
          end

          assert_match(/Removing cache/, output)
          assert_match(/✓ Cache cleaned/, output)
          assert_false(Dir.exist?(cache_path))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # cache prune コマンドのテスト
  sub_test_case "cache prune command" do
    test "removes unused caches and keeps referenced caches" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::CACHE_DIR)

          # テスト用の環境を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          # テスト用のキャッシュディレクトリを作成（使用中と未使用の両方）
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000'))  # 使用中
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'unused1-20240101_120000'))  # 未使用
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'picoruby-esp32', 'def5678-20250102_120000'))  # 使用中
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'picoruby', 'ghi9012-20250103_120000'))  # 使用中
          FileUtils.mkdir_p(File.join(Pra::Env::CACHE_DIR, 'picoruby', 'unused2-20240101_120000'))  # 未使用

          output = capture_stdout do
            Pra::Commands::Cache.start(['prune'])
          end

          assert_match(/Keep: R2P2-ESP32\/abc1234-20250101_120000/, output)
          assert_match(/Remove: R2P2-ESP32\/unused1-20240101_120000/, output)
          assert_match(/Keep: picoruby-esp32\/def5678-20250102_120000/, output)
          assert_match(/Keep: picoruby\/ghi9012-20250103_120000/, output)
          assert_match(/Remove: picoruby\/unused2-20240101_120000/, output)
          assert_match(/✓ Pruning completed/, output)

          # 使用中のキャッシュは残っている
          assert_true(Dir.exist?(File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000')))
          assert_true(Dir.exist?(File.join(Pra::Env::CACHE_DIR, 'picoruby-esp32', 'def5678-20250102_120000')))
          assert_true(Dir.exist?(File.join(Pra::Env::CACHE_DIR, 'picoruby', 'ghi9012-20250103_120000')))

          # 未使用のキャッシュは削除されている
          assert_false(Dir.exist?(File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'unused1-20240101_120000')))
          assert_false(Dir.exist?(File.join(Pra::Env::CACHE_DIR, 'picoruby', 'unused2-20240101_120000')))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "handles empty cache directory gracefully" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::CACHE_DIR)

          output = capture_stdout do
            Pra::Commands::Cache.start(['prune'])
          end

          assert_match(/Pruning unused cache/, output)
          assert_match(/✓ Pruning completed/, output)
        ensure
          Dir.chdir(original_dir)
        end
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
