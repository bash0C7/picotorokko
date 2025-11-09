require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

class PraCommandsEnvTest < Test::Unit::TestCase
  # env show コマンドのテスト
  sub_test_case "env show command" do
    test "shows '(not set)' when no environment is configured" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

          output = capture_stdout do
            Pra::Commands::Env.start(['show'])
          end

          assert_match(/Current environment definition: \(not set\)/, output)
          assert_match(/Run 'pra env set ENV_NAME' to set an environment definition/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "shows error when environment is set but not found in config" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

          # current環境を設定するが、定義は作成しない
          Pra::Env.set_current_env('missing-env')

          output = capture_stdout do
            Pra::Commands::Env.start(['show'])
          end

          assert_match(/Error: Environment 'missing-env' not found/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "shows environment details when properly configured" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

          # テスト用の環境を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info, notes: 'Test environment')
          Pra::Env.set_current_env('test-env')

          output = capture_stdout do
            Pra::Commands::Env.start(['show'])
          end

          assert_match(/Current environment definition: test-env/, output)
          assert_match(/Repo versions:/, output)
          assert_match(/R2P2-ESP32: abc1234 \(20250101_120000\)/, output)
          assert_match(/picoruby-esp32: def5678 \(20250102_120000\)/, output)
          assert_match(/picoruby: ghi9012 \(20250103_120000\)/, output)
          assert_match(/Notes: Test environment/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "shows symlink information when available" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

          # テスト用の環境とシンボリックリンクを作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)
          Pra::Env.set_current_env('test-env')

          # BUILD_DIRとcurrentシンボリックリンクを作成（正しいenv_hashを使用）
          r2p2_hash = "#{r2p2_info['commit']}-#{r2p2_info['timestamp']}"
          esp32_hash = "#{esp32_info['commit']}-#{esp32_info['timestamp']}"
          picoruby_hash = "#{picoruby_info['commit']}-#{picoruby_info['timestamp']}"
          env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)

          FileUtils.mkdir_p(Pra::Env::BUILD_DIR)
          target = File.join(Pra::Env::BUILD_DIR, env_hash)
          FileUtils.mkdir_p(target)
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          FileUtils.ln_s(env_hash, current_link)

          output = capture_stdout do
            Pra::Commands::Env.start(['show'])
          end

          assert_match(/Symlink: current -> #{Regexp.escape(env_hash)}\//, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # env set コマンドのテスト
  sub_test_case "env set command" do
    test "raises error when environment does not exist" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Env.start(['set', 'non-existent'])
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "shows error when build directory does not exist" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

          # 環境定義は作成するが、ビルドディレクトリは作成しない
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250101_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250101_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          output = capture_stdout do
            Pra::Commands::Env.start(['set', 'test-env'])
          end

          assert_match(/Error: Build environment not found/, output)
          assert_match(/Run 'pra build setup test-env' first/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "successfully switches environment when build exists" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

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

          output = capture_stdout do
            Pra::Commands::Env.start(['set', 'test-env'])
          end

          assert_match(/Switching to environment definition: test-env/, output)
          assert_match(/✓ Switched to environment definition 'test-env'/, output)

          # currentが正しく設定されていることを確認
          assert_equal('test-env', Pra::Env.get_current_env)

          # シンボリックリンクが作成されていることを確認
          current_link = File.join(Pra::Env::BUILD_DIR, 'current')
          assert_true(File.symlink?(current_link))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # env latest コマンドのテスト
  sub_test_case "env latest command" do
    test "fetches latest commits and creates environment" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

          # Git操作をモック化
          stub_git_operations do |stubs|
            output = capture_stdout do
              Pra::Commands::Env.start(['latest'])
            end

            # 出力確認
            assert_match(/Fetching latest commits from GitHub/, output)
            assert_match(/Checking R2P2-ESP32/, output)
            assert_match(/Checking picoruby-esp32/, output)
            assert_match(/Checking picoruby/, output)
            assert_match(/✓ R2P2-ESP32: abc1234 \(20250101_120000\)/, output)
            assert_match(/✓ picoruby-esp32: def5678 \(20250102_120000\)/, output)
            assert_match(/✓ picoruby: ghi9012 \(20250103_120000\)/, output)
            assert_match(/Saving as environment definition 'latest'/, output)
            assert_match(/✓ Environment definition 'latest' created successfully/, output)

            # 環境が正しく保存されているか確認
            env_config = Pra::Env.get_environment('latest')
            assert_not_nil(env_config)
            assert_equal('abc1234', env_config['R2P2-ESP32']['commit'])
            assert_equal('20250101_120000', env_config['R2P2-ESP32']['timestamp'])
            assert_equal('def5678', env_config['picoruby-esp32']['commit'])
            assert_equal('20250102_120000', env_config['picoruby-esp32']['timestamp'])
            assert_equal('ghi9012', env_config['picoruby']['commit'])
            assert_equal('20250103_120000', env_config['picoruby']['timestamp'])
            assert_equal('Auto-generated latest versions', env_config['notes'])
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "handles fetch failure gracefully" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

          # Git操作をモック化（失敗させる）
          stub_git_operations(fail_fetch: true) do |stubs|
            assert_raise(RuntimeError) do
              capture_stdout do
                Pra::Commands::Env.start(['latest'])
              end
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "handles clone failure gracefully" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          FileUtils.rm_rf(Pra::Env::BUILD_DIR)

          # Git操作をモック化（cloneを失敗させる）
          stub_git_operations(fail_clone: true) do |stubs|
            assert_raise(RuntimeError) do
              capture_stdout do
                Pra::Commands::Env.start(['latest'])
              end
            end
          end
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

  # Git操作をスタブ化するヘルパーメソッド
  def stub_git_operations(fail_fetch: false, fail_clone: false)
    # テスト用のコミット情報
    test_commits = {
      'R2P2-ESP32' => { commit: 'abc1234', timestamp: '20250101_120000' },
      'picoruby-esp32' => { commit: 'def5678', timestamp: '20250102_120000' },
      'picoruby' => { commit: 'ghi9012', timestamp: '20250103_120000' }
    }

    # 元のメソッドを保存
    original_fetch = Pra::Env.method(:fetch_remote_commit)
    call_count = { fetch: 0, clone: 0 }

    # fetch_remote_commitをスタブ化
    Pra::Env.define_singleton_method(:fetch_remote_commit) do |repo_url, ref = 'HEAD'|
      call_count[:fetch] += 1
      return nil if fail_fetch

      # リポジトリURLから名前を取得
      repo_name = Pra::Env::REPOS.key(repo_url)
      test_commits[repo_name][:commit]
    end

    # systemコマンドをスタブ化（Kernelモジュールに対して）
    original_system = Kernel.instance_method(:system)
    Kernel.module_eval do
      define_method(:system) do |*args|
        cmd = args.join(' ')
        if cmd.include?('git clone')
          call_count[:clone] += 1
          return false if fail_clone

          # 一時ディレクトリにダミーのgitリポジトリを作成
          # コマンド引数から最後の引数（デスティネーションパス）を抽出
          # シェルワード形式（引用符付き）に対応
          if cmd =~ /git clone.* (\S+)\s+2>/
            dest_path = $1.gsub(/['"]/, '') # 引用符を削除
            FileUtils.mkdir_p(dest_path)
            FileUtils.mkdir_p(File.join(dest_path, '.git'))
          end
          true
        else
          original_system.bind(self).call(*args)
        end
      end
    end

    # バッククォートコマンドをスタブ化
    original_backtick = Kernel.instance_method(:`)
    Kernel.module_eval do
      define_method(:`) do |cmd|
        if cmd.include?('git rev-parse --short=7 HEAD')
          # 現在の作業ディレクトリからリポジトリ名を推測
          pwd = Dir.pwd
          repo_name = Pra::Env::REPOS.keys.find { |name| pwd.include?(name) }
          test_commits[repo_name][:commit] + "\n"
        elsif cmd.include?('git show -s --format=%ci HEAD')
          # タイムスタンプを日付形式で返す
          pwd = Dir.pwd
          repo_name = Pra::Env::REPOS.keys.find { |name| pwd.include?(name) }
          "2025-01-0#{Pra::Env::REPOS.keys.index(repo_name) + 1} 12:00:00 +0900\n"
        else
          original_backtick.bind(self).call(cmd)
        end
      end
    end

    begin
      yield({ commits: test_commits, call_count: call_count })
    ensure
      # 元のメソッドを復元
      Pra::Env.define_singleton_method(:fetch_remote_commit, original_fetch)
      Kernel.module_eval do
        define_method(:system, original_system)
        define_method(:`, original_backtick)
      end
    end
  end
end
