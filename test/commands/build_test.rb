require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsBuildTest < Test::Unit::TestCase
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

  # build setup コマンドのテスト
  sub_test_case "build setup command" do
    test "sets up build environment when caches exist" do
      # テスト用の環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      # キャッシュディレクトリを作成（setup に必要）
      r2p2_cache = File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000')
      esp32_cache = File.join(Pra::Env::CACHE_DIR, 'picoruby-esp32', 'def5678-20250102_120000')
      picoruby_cache = File.join(Pra::Env::CACHE_DIR, 'picoruby', 'ghi9012-20250103_120000')

      FileUtils.mkdir_p(File.join(r2p2_cache, 'components', 'picoruby-esp32'))
      FileUtils.mkdir_p(File.join(esp32_cache))
      FileUtils.mkdir_p(File.join(picoruby_cache))

      # テストファイルを作成して、コピーがされていることを確認できるようにする
      File.write(File.join(r2p2_cache, 'README.md'), 'R2P2-ESP32')

      output = capture_stdout do
        Pra::Commands::Build.start(['setup', 'test-env'])
      end

      # 出力を確認
      assert_match(/Setting up build environment from environment definition: test-env/, output)
      assert_match(/Creating build environment at/, output)
      assert_match(/✓ Build environment ready for environment definition: test-env/, output)

      # ビルドディレクトリが作成されたことを確認
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pra::Env.get_build_path(env_hash)

      assert_true(Dir.exist?(build_path))
      assert_true(Dir.exist?(File.join(build_path, 'R2P2-ESP32')))

      # ファイルがコピーされたことを確認
      assert_true(File.exist?(File.join(build_path, 'R2P2-ESP32', 'README.md')))

      # シンボリックリンクが作成されたことを確認
      current_link = File.join(Pra::Env::BUILD_DIR, 'current')
      assert_true(File.symlink?(current_link))
    end

    test "skips setup when build environment already exists" do
      # テスト用の環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      # キャッシュとビルド環境を作成
      r2p2_cache = File.join(Pra::Env::CACHE_DIR, 'R2P2-ESP32', 'abc1234-20250101_120000')
      esp32_cache = File.join(Pra::Env::CACHE_DIR, 'picoruby-esp32', 'def5678-20250102_120000')
      picoruby_cache = File.join(Pra::Env::CACHE_DIR, 'picoruby', 'ghi9012-20250103_120000')

      FileUtils.mkdir_p(File.join(r2p2_cache, 'components', 'picoruby-esp32'))
      FileUtils.mkdir_p(File.join(esp32_cache))
      FileUtils.mkdir_p(File.join(picoruby_cache))

      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pra::Env.get_build_path(env_hash)

      FileUtils.mkdir_p(File.join(build_path, 'R2P2-ESP32'))

      output = capture_stdout do
        Pra::Commands::Build.start(['setup', 'test-env'])
      end

      # 出力を確認
      assert_match(/Build environment already exists/, output)
      assert_match(/✓ Build environment ready for environment definition: test-env/, output)
    end
  end

  # build list コマンドのテスト
  sub_test_case "build list command" do
    test "shows 'No build environments found' when build directory is empty" do
      output = capture_stdout do
        Pra::Commands::Build.start(['list'])
      end

      assert_match(/=== Build Environments ===/, output)
      assert_match(/Current: \(not set\)/, output)
      assert_match(/No build environments found/, output)
    end

    test "lists build environments when they exist" do
      # テスト用のビルド環境を作成
      FileUtils.mkdir_p(Pra::Env::BUILD_DIR)
      FileUtils.mkdir_p(File.join(Pra::Env::BUILD_DIR, 'env1-hash'))
      FileUtils.mkdir_p(File.join(Pra::Env::BUILD_DIR, 'env2-hash'))

      output = capture_stdout do
        Pra::Commands::Build.start(['list'])
      end

      assert_match(/=== Build Environments ===/, output)
      assert_match(/Available:/, output)
      assert_match(/env1-hash/, output)
      assert_match(/env2-hash/, output)
    end

    test "shows current symlink when it exists" do
      # ビルド環境とシンボリックリンクを作成
      FileUtils.mkdir_p(Pra::Env::BUILD_DIR)
      target_dir = 'test-env-hash'
      FileUtils.mkdir_p(File.join(Pra::Env::BUILD_DIR, target_dir))

      current_link = File.join(Pra::Env::BUILD_DIR, 'current')
      FileUtils.ln_s(target_dir, current_link)

      output = capture_stdout do
        Pra::Commands::Build.start(['list'])
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
          Pra::Commands::Build.start(['clean', 'non-existent'])
        end
      end
    end

    test "shows message when build directory does not exist" do
      # 環境定義を作成するが、ビルドディレクトリは作成しない
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      output = capture_stdout do
        Pra::Commands::Build.start(['clean', 'test-env'])
      end

      assert_match(/Build environment directory not found/, output)
    end

    test "removes build directory when it exists" do
      # 環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

      # ビルドディレクトリを作成
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pra::Env.get_build_path(env_hash)
      FileUtils.mkdir_p(build_path)

      assert_true(Dir.exist?(build_path))

      output = capture_stdout do
        Pra::Commands::Build.start(['clean', 'test-env'])
      end

      assert_match(/Removing build environment for environment definition/, output)
      assert_match(/✓ Build environment directory removed/, output)
      assert_false(Dir.exist?(build_path))
    end

    test "removes current symlink when cleaning with 'current' argument" do
      # 環境定義を作成
      r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
      esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
      picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

      Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)
      Pra::Env.set_current_env('test-env')

      # ビルドディレクトリとシンボリックリンクを作成
      r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
      esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
      picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
      env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      build_path = Pra::Env.get_build_path(env_hash)
      FileUtils.mkdir_p(build_path)

      current_link = File.join(Pra::Env::BUILD_DIR, 'current')
      FileUtils.ln_s(env_hash, current_link)

      assert_true(File.symlink?(current_link))

      output = capture_stdout do
        Pra::Commands::Build.start(['clean', 'current'])
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
