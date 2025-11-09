require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsPatchTest < Test::Unit::TestCase
  # patch export コマンドのテスト
  sub_test_case "patch export command" do
    test "exports changes from build environment to patch directory" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          # テスト用の環境定義を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          # ビルドディレクトリとファイルを作成
          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          # git リポジトリとして初期化
          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)
          Dir.chdir(r2p2_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('test.txt', 'initial')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
            File.write('test.txt', 'modified')
          end

          output = capture_stdout do
            Pra::Commands::Patch.start(['export', 'test-env'])
          end

          # 出力を確認
          assert_match(/Exporting patches from: test-env/, output)
          assert_match(/✓ Patches exported/, output)

          # パッチディレクトリが作成されたことを確認
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'R2P2-ESP32')
          assert_true(Dir.exist?(patch_dir))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "raises error when build environment not found" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          # テスト用の環境定義を作成するが、ビルド環境は作成しない
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Patch.start(['export', 'test-env'])
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "exports patches with env_name='current'" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)
          Dir.chdir(r2p2_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('test.txt', 'initial')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
            File.write('test.txt', 'modified')
          end

          # currentシンボリックリンクを作成
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          Pra::Env.create_symlink(File.basename(build_path), current_link)
          Pra::Env.set_current_env('test-env')

          output = capture_stdout do
            Pra::Commands::Patch.start(['export'])
          end

          assert_match(/Exporting patches from: test-env/, output)
          assert_match(/✓ Patches exported/, output)
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'R2P2-ESP32')
          assert_true(Dir.exist?(patch_dir))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "exports with picoruby-esp32 changes" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          # R2P2-ESP32 リポジトリを作成（最初に作成する必要がある）
          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)
          Dir.chdir(r2p2_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('dummy.txt', 'dummy')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
          end

          # picoruby-esp32 リポジトリを作成
          picoruby_esp32_work = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32')
          FileUtils.mkdir_p(picoruby_esp32_work)
          Dir.chdir(picoruby_esp32_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('esp32_file.txt', 'initial')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
            File.write('esp32_file.txt', 'line1\nline2\nesp32 modified')
          end

          output = capture_stdout do
            Pra::Commands::Patch.start(['export', 'test-env'])
          end

          assert_match(/picoruby-esp32:/, output)
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'picoruby-esp32')
          assert_true(Dir.exist?(patch_dir))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "exports with no changes in repository" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)
          Dir.chdir(r2p2_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('test.txt', 'initial')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
          end

          output = capture_stdout do
            Pra::Commands::Patch.start(['export', 'test-env'])
          end

          assert_match(/R2P2-ESP32: \(no changes\)/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # patch apply コマンドのテスト
  sub_test_case "patch apply command" do
    test "applies patches to build environment" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          # テスト用の環境定義を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          # ビルドディレクトリを作成
          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)

          # パッチファイルを作成
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'R2P2-ESP32')
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, 'patch.txt'), 'patched content')

          output = capture_stdout do
            Pra::Commands::Patch.start(['apply', 'test-env'])
          end

          # 出力を確認
          assert_match(/Applying patches/, output)
          assert_match(/✓ Patches applied/, output)

          # パッチが適用されたことを確認
          assert_true(File.exist?(File.join(r2p2_work, 'patch.txt')))
          assert_equal('patched content', File.read(File.join(r2p2_work, 'patch.txt')))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "skips patch apply when no current environment is set" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          output = capture_stdout do
            Pra::Commands::Patch.start(['apply'])
          end

          # 出力を確認
          assert_match(/No current environment - skipping patch apply/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "applies patches with env_name='current'" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)

          # パッチファイルを作成
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'R2P2-ESP32')
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, 'patch.txt'), 'patched content')

          # currentシンボリックリンクを作成
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          Pra::Env.create_symlink(File.basename(build_path), current_link)
          Pra::Env.set_current_env('test-env')

          output = capture_stdout do
            Pra::Commands::Patch.start(['apply'])
          end

          assert_match(/Applying patches/, output)
          assert_match(/✓ Patches applied/, output)
          assert_true(File.exist?(File.join(r2p2_work, 'patch.txt')))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "applies patches with picoruby-esp32" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          picoruby_esp32_work = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32')
          FileUtils.mkdir_p(picoruby_esp32_work)

          # パッチファイルを作成
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'picoruby-esp32')
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, 'patch.txt'), 'patched content')

          output = capture_stdout do
            Pra::Commands::Patch.start(['apply', 'test-env'])
          end

          assert_match(/Applied picoruby-esp32/, output)
          assert_true(File.exist?(File.join(picoruby_esp32_work, 'patch.txt')))
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
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Patch.start(['apply', 'nonexistent-env'])
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # patch diff コマンドのテスト
  sub_test_case "patch diff command" do
    test "displays patch differences" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          # テスト用の環境定義を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          # ビルドディレクトリを作成
          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)

          # git リポジトリとして初期化
          Dir.chdir(r2p2_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('test.txt', 'initial')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
          end

          # パッチディレクトリを作成
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'R2P2-ESP32')
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, 'patch.txt'), 'patched content')

          # currentシンボリックリンクを作成
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          Pra::Env.create_symlink(File.basename(build_path), current_link)
          Pra::Env.set_current_env('test-env')

          output = capture_stdout do
            Pra::Commands::Patch.start(['diff', 'test-env'])
          end

          # 出力を確認
          assert_match(/=== Patch Differences ===/, output)
          assert_match(/Stored patches:/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "raises error when no current environment is set" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          # テスト用の環境定義を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Patch.start(['diff'])
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "displays patch diff with env_name='current'" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)

          # git リポジトリとして初期化
          Dir.chdir(r2p2_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('test.txt', 'initial')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
            File.write('test.txt', 'modified')
          end

          # パッチディレクトリを作成
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'R2P2-ESP32')
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, 'patch.txt'), 'patched content')

          # currentシンボリックリンクを作成
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          Pra::Env.create_symlink(File.basename(build_path), current_link)
          Pra::Env.set_current_env('test-env')

          output = capture_stdout do
            Pra::Commands::Patch.start(['diff'])
          end

          assert_match(/=== Patch Differences ===/, output)
          assert_match(/R2P2-ESP32:/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "displays patch diff with working changes" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)

          # git リポジトリとして初期化し、変更を作成
          Dir.chdir(r2p2_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('test.txt', 'initial')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
            File.write('test.txt', 'modified')
          end

          output = capture_stdout do
            Pra::Commands::Patch.start(['diff', 'test-env'])
          end

          assert_match(/Working changes:/, output)
          assert_match(/test\.txt/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "displays patch diff with no patches directory" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)

          output = capture_stdout do
            Pra::Commands::Patch.start(['diff', 'test-env'])
          end

          assert_match(/\(no patches directory\)/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "displays patch diff for picoruby repository" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)
          FileUtils.rm_rf(Pra::Env::PATCH_DIR)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
          build_path = Pra::Env.get_build_path(env_hash)

          picoruby_work = File.join(build_path, 'R2P2-ESP32', 'components', 'picoruby-esp32', 'picoruby')
          FileUtils.mkdir_p(picoruby_work)

          Dir.chdir(picoruby_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('ruby_file.rb', 'puts "hello"')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
          end

          # picorubyパッチディレクトリを作成
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'picoruby')
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, 'ruby_file.rb'), 'patch content')

          output = capture_stdout do
            Pra::Commands::Patch.start(['diff', 'test-env'])
          end

          assert_match(/picoruby:/, output)
          assert_match(/Stored patches:/, output)
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
