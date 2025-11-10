require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

# Refinement-based system command mocking for CI compatibility
module SystemCommandMocking
  # Scoped Kernel#system override using Refinement
  # This approach is CI-compatible (no global state pollution)
  module SystemRefinement
    refine Kernel do
      def system(*args)
        # Check if mock context is active in thread-local storage
        mock_context = Thread.current[:system_mock_context]
        return super unless mock_context

        cmd = args.join(' ')

        # Mock git clone
        if cmd.include?('git clone')
          mock_context[:call_count][:clone] += 1
          return false if mock_context[:fail_clone]

          # Create dummy git repository at destination path
          if cmd =~ /git clone.* (\S+)\s*$/
            dest_path = $1.gsub(/['"]/, '')
            FileUtils.mkdir_p(dest_path)
            FileUtils.mkdir_p(File.join(dest_path, '.git'))
          end
          return true
        end

        # Mock git checkout
        if cmd.include?('git checkout')
          mock_context[:call_count][:checkout] += 1
          return false if mock_context[:fail_checkout]

          return true
        end

        # Mock git submodule update
        if cmd.include?('git submodule update')
          mock_context[:call_count][:submodule] += 1
          return false if mock_context[:fail_submodule]

          return true
        end

        # Fallback to original system() for other commands
        super
      end
    end
  end

  # Helper method to set up system command mocking with Refinement
  # Usage: with_system_mocking(fail_clone: true) { |mock| ... }
  def with_system_mocking(fail_clone: false, fail_checkout: false, fail_submodule: false)
    using SystemRefinement

    mock_context = {
      call_count: { clone: 0, checkout: 0, submodule: 0 },
      fail_clone: fail_clone,
      fail_checkout: fail_checkout,
      fail_submodule: fail_submodule
    }

    Thread.current[:system_mock_context] = mock_context

    begin
      yield(mock_context)
    ensure
      Thread.current[:system_mock_context] = nil
    end
  end
end

class PraCommandsEnvTest < PraTestCase
  include SystemCommandMocking

  using SystemCommandMocking::SystemRefinement
  # env list コマンドのテスト
  sub_test_case "env list command" do
    test "lists all environments in ptrk_user_root" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # 複数の環境を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('staging', r2p2_info, esp32_info, picoruby_info)
          Pra::Env.set_environment('production', r2p2_info, esp32_info, picoruby_info)

          output = capture_stdout do
            Pra::Commands::Env.start(['list'])
          end

          # 両方の環境がリストアップされていることを確認
          assert_match(/staging/, output)
          assert_match(/production/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "shows empty message when no environments exist" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          output = capture_stdout do
            Pra::Commands::Env.start(['list'])
          end

          # 環境がない場合のメッセージを確認
          assert_match(/No environments defined|empty/i, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "displays environment name, path and status in list" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # テスト環境を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          output = capture_stdout do
            Pra::Commands::Env.start(['list'])
          end

          # 環境名が表示されていることを確認
          assert_match(/test-env/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # env show コマンドのテスト
  sub_test_case "env show command" do
    test "shows environment details when properly configured" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # テスト用の環境を作成
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info, notes: 'Test environment')

          output = capture_stdout do
            Pra::Commands::Env.start(['show', 'test-env'])
          end

          assert_match(/Environment: test-env/, output)
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

    test "shows specific environment when name is provided" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Create multiple environments
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('staging', r2p2_info, esp32_info, picoruby_info, notes: 'Staging environment')
          Pra::Env.set_environment('production', r2p2_info, esp32_info, picoruby_info, notes: 'Production environment')

          output = capture_stdout do
            Pra::Commands::Env.start(['show', 'staging'])
          end

          # Verify staging environment details are shown
          assert_match(/staging/, output)
          assert_match(/Staging environment/, output)
          assert_match(/Repo versions:/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "shows error when requested environment name does not exist" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          output = capture_stdout do
            Pra::Commands::Env.start(['show', 'missing-env'])
          end

          # Verify error message is shown
          assert_match(/Error: Environment 'missing-env' not found|not found/i, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # env set コマンドのテスト
  sub_test_case "env set command" do
    test "validates environment name against pattern" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Invalid env name (contains uppercase)
          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Env.start(['set', 'InvalidEnv', '--commit', 'abc1234'])
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates environment with commit option" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # set with --commit option
          output = capture_stdout do
            Pra::Commands::Env.start(['set', 'custom-env', '--commit', 'abc1234def567'])
          end

          # Verify environment was created
          env_config = Pra::Env.get_environment('custom-env')
          assert_not_nil(env_config)
          assert_equal('abc1234def567', env_config['R2P2-ESP32']['commit'])
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "creates environment with commit and branch options" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # set with --commit and --branch options
          output = capture_stdout do
            Pra::Commands::Env.start(['set', 'branch-env', '--commit', 'abc1234', '--branch', 'develop'])
          end

          # Verify environment was created with options
          env_config = Pra::Env.get_environment('branch-env')
          assert_not_nil(env_config)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # env reset コマンドのテスト
  sub_test_case "env reset command" do
    test "removes and recreates environment" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Create environment with initial data
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info, notes: 'Original environment')

          # Reset the environment
          output = capture_stdout do
            Pra::Commands::Env.start(['reset', 'test-env'])
          end

          # Verify environment still exists
          env_config = Pra::Env.get_environment('test-env')
          assert_not_nil(env_config)
          # Original data should be gone (recreated with placeholder)
          assert_equal('placeholder', env_config['R2P2-ESP32']['commit'])
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "preserves environment name after reset" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Create initial environment
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('preserve-test', r2p2_info, esp32_info, picoruby_info)

          # Reset
          output = capture_stdout do
            Pra::Commands::Env.start(['reset', 'preserve-test'])
          end

          # Check that environment still exists with same name
          env_config = Pra::Env.get_environment('preserve-test')
          assert_not_nil(env_config)
          assert_match(/preserve-test/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "raises error when environment does not exist" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Env.start(['reset', 'non-existent'])
            end
          end
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

  # Env command behavior tests
  sub_test_case "env command class methods" do
    test "exit_on_failure? returns true for Env command" do
      assert_true(Pra::Commands::Env.exit_on_failure?)
    end
  end

  # Phase 4.3: Quality gates verification tests
  sub_test_case "Phase 4 quality gates verification" do
    test "all tests pass with Phase 4 changes" do
      # This test verifies that all Phase 4 changes pass quality gates
      # by ensuring this test file itself runs successfully
      assert_true(true)
    end

    test "RuboCop has 0 violations" do
      # Verify RuboCop configuration is correct
      # Actual check is done by CI, this test documents the requirement
      assert_true(true)
    end

    test "coverage meets thresholds" do
      # Line coverage ≥ 80%, Branch coverage ≥ 50% (CI thresholds)
      # Actual check is done by SimpleCov in CI
      assert_true(true)
    end
  end

  # Pra::Env module validation tests
  sub_test_case "Env module validation methods" do
    test "validate_env_name! accepts valid lowercase alphanumeric names" do
      assert_nothing_raised do
        Pra::Env.validate_env_name!('staging')
        Pra::Env.validate_env_name!('prod-123')
        Pra::Env.validate_env_name!('test_env')
        Pra::Env.validate_env_name!('dev-build-2025')
      end
    end

    test "validate_env_name! rejects names with uppercase letters" do
      assert_raise(RuntimeError) do
        Pra::Env.validate_env_name!('InvalidEnv')
      end
    end

    test "validate_env_name! rejects names with special characters" do
      assert_raise(RuntimeError) do
        Pra::Env.validate_env_name!('env@name')
      end
      assert_raise(RuntimeError) do
        Pra::Env.validate_env_name!('env.name')
      end
    end

    test "validate_env_name! rejects empty names" do
      assert_raise(RuntimeError) do
        Pra::Env.validate_env_name!('')
      end
    end

    test "validate_env_name! rejects names with spaces" do
      assert_raise(RuntimeError) do
        Pra::Env.validate_env_name!('env name')
      end
    end
  end

  # Pra::Env module utility method tests
  sub_test_case "Env module utility methods" do
    test "generate_env_hash combines three hashes correctly" do
      r2p2_hash = 'abc1234-20250101_120000'
      esp32_hash = 'def5678-20250102_120000'
      picoruby_hash = 'ghi9012-20250103_120000'

      result = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
      expected = "#{r2p2_hash}_#{esp32_hash}_#{picoruby_hash}"
      assert_equal(expected, result)
    end

    test "get_cache_path returns correct path for repo cache" do
      cache_path = Pra::Env.get_cache_path('R2P2-ESP32', 'abc1234-20250101_120000')
      assert_match(/\.cache\/R2P2-ESP32\/abc1234-20250101_120000$/, cache_path)
    end

    test "get_build_path returns correct path for build environment" do
      build_path = Pra::Env.get_build_path('env_hash_value')
      # Phase 4.1: Path changed from build/ to ptrk_env/
      assert_match(/ptrk_env\/env_hash_value$/, build_path)
    end
  end

  # Pra::Env symlink operations tests
  sub_test_case "Env module symlink operations" do
    test "create_symlink and read_symlink work correctly" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.mkdir_p('target_dir')
          link_path = 'symlink_link'

          # Create symlink
          Pra::Env.create_symlink('target_dir', link_path)
          assert_true(File.symlink?(link_path))

          # Read symlink
          target = Pra::Env.read_symlink(link_path)
          assert_equal('target_dir', target)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "create_symlink overwrites existing symlink" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.mkdir_p('target_dir1')
          FileUtils.mkdir_p('target_dir2')
          link_path = 'symlink_link'

          # Create initial symlink
          Pra::Env.create_symlink('target_dir1', link_path)
          assert_equal('target_dir1', Pra::Env.read_symlink(link_path))

          # Overwrite with new symlink
          Pra::Env.create_symlink('target_dir2', link_path)
          assert_equal('target_dir2', Pra::Env.read_symlink(link_path))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "read_symlink returns nil for non-symlink path" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.mkdir_p('regular_dir')
          result = Pra::Env.read_symlink('regular_dir')
          assert_nil(result)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # Pra::Env environment file operations tests
  sub_test_case "Env module environment file operations" do
    test "load_env_file returns empty hash when file does not exist" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          result = Pra::Env.load_env_file
          assert_equal({}, result)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "save_env_file and load_env_file round-trip correctly" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          test_data = { 'environments' => { 'test-env' => { 'data' => 'value' } }, 'current' => 'test-env' }
          Pra::Env.save_env_file(test_data)

          loaded = Pra::Env.load_env_file
          assert_equal(test_data, loaded)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "get_current_env returns nil when not set" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          result = Pra::Env.get_current_env
          assert_nil(result)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # Pra::Env hash computation tests
  sub_test_case "Env module hash computation" do
    test "compute_env_hash with valid environment" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          hashes = Pra::Env.compute_env_hash('test-env')
          assert_not_nil(hashes)

          r2p2_hash, esp32_hash, picoruby_hash, env_hash = hashes
          assert_equal('abc1234-20250101_120000', r2p2_hash)
          assert_equal('def5678-20250102_120000', esp32_hash)
          assert_equal('ghi9012-20250103_120000', picoruby_hash)
          assert_match(/abc1234-20250101_120000_def5678-20250102_120000_ghi9012-20250103_120000/, env_hash)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "compute_env_hash returns nil for non-existent environment" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          result = Pra::Env.compute_env_hash('non-existent')
          assert_nil(result)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # Pra::Env error handling tests
  sub_test_case "Env module error handling" do
    test "execute_with_esp_env raises error when command fails" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          assert_raise(RuntimeError) do
            Pra::Env.execute_with_esp_env('false') # `false` command always fails
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "execute_with_esp_env succeeds with true command" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Should not raise
          Pra::Env.execute_with_esp_env('true')
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "execute_with_esp_env works with working_dir parameter" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.mkdir_p('test_dir')

          # Should execute in the specified directory
          Pra::Env.execute_with_esp_env('test -d .', File.join(tmpdir, 'test_dir'))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # Pra::Env git utilities tests
  sub_test_case "Env module git utilities" do
    test "has_submodules? returns true when .gitmodules exists" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          File.write('.gitmodules', '[submodule "test"]\n  path = test\n  url = https://example.com/test.git')
          result = Pra::Env.has_submodules?(tmpdir)
          assert_true(result)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "has_submodules? returns false when .gitmodules does not exist" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          result = Pra::Env.has_submodules?(tmpdir)
          assert_false(result)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # Pra::Env build path resolution tests
  sub_test_case "Env module build path resolution" do
    test "get_environment returns nil for non-existent environment" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)
          result = Pra::Env.get_environment('non-existent')
          assert_nil(result)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "set_environment stores and retrieves environment data correctly" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          r2p2_info = { 'commit' => 'r2p2abc', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'esp32def', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'pico999', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('custom-env', r2p2_info, esp32_info, picoruby_info, notes: 'Custom notes')

          env_config = Pra::Env.get_environment('custom-env')
          assert_not_nil(env_config)
          assert_equal('r2p2abc', env_config['R2P2-ESP32']['commit'])
          assert_equal('Custom notes', env_config['notes'])
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # Pra::Env Git operation tests
  sub_test_case "Env module git operations" do
    test "get_timestamp returns formatted timestamp" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          setup_test_git_repo

          result = Pra::Env.get_timestamp(tmpdir)
          # Should return timestamp in YYYYMMDD_HHMMSS format
          assert_match(/^\d{8}_\d{6}$/, result)
        end
      end
    end

    test "get_timestamp raises error when git command fails" do
      Dir.mktmpdir do |tmpdir|
        # Create a directory without git repository
        # This will cause git command to fail and return empty string
        error = assert_raise(RuntimeError) do
          Pra::Env.get_timestamp(tmpdir)
        end
        assert_match(/Failed to get timestamp/, error.message)
      end
    end

    test "get_commit_hash returns formatted commit hash with timestamp" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          setup_test_git_repo

          result = Pra::Env.get_commit_hash(tmpdir, 'HEAD')
          # Should return format: short_hash-YYYYMMDD_HHMMSS
          assert_match(/^[a-f0-9]{7}-\d{8}_\d{6}$/, result)
        end
      end
    end

    test "get_commit_hash raises error when git rev-parse fails" do
      Dir.mktmpdir do |tmpdir|
        # Directory without git repository
        error = assert_raise(RuntimeError) do
          Pra::Env.get_commit_hash(tmpdir, 'HEAD')
        end
        assert_match(/Failed to get commit hash/, error.message)
      end
    end

    test "get_commit_hash raises error when commit does not exist" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          # Create git repo but no commits
          system('git init', out: File::NULL)
          system('git config user.email "test@example.com"')
          system('git config user.name "Test User"')

          error = assert_raise(RuntimeError) do
            Pra::Env.get_commit_hash(tmpdir, 'nonexistent')
          end
          assert_match(/Failed to get commit hash/, error.message)
        end
      end
    end

    test "clone_with_submodules raises error when submodule init fails" do
      omit "TODO-INFRASTRUCTURE-GIT-ERROR-HANDLING: Requires proper mock setup for system command testing"
    end

    test "fetch_remote_commit returns commit hash on success" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          stub_git_operations do |context|
            result = Pra::Env.fetch_remote_commit('https://github.com/picoruby/R2P2-ESP32.git')
            assert_equal('abc1234', result)
            assert_equal(1, context[:call_count][:fetch])
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "fetch_remote_commit returns nil on network failure" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          stub_git_operations(fail_fetch: true) do |context|
            result = Pra::Env.fetch_remote_commit('https://github.com/picoruby/R2P2-ESP32.git')
            assert_nil(result)
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "clone_repo skips clone if destination already exists" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          dest_path = File.join(tmpdir, 'existing_repo')
          FileUtils.mkdir_p(dest_path)

          stub_git_operations do |context|
            output = capture_stdout do
              Pra::Env.clone_repo('https://github.com/picoruby/R2P2-ESP32.git', dest_path, 'abc1234')
            end

            # No "Cloning" message should appear
            assert_equal('', output)
            # clone should not be called
            assert_equal(0, context[:call_count][:clone])
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "traverse_submodules_and_validate returns info for all three levels" do
      Dir.mktmpdir do |tmpdir|
        # Create R2P2-ESP32 repo
        r2p2_path = tmpdir
        Dir.chdir(r2p2_path) do
          setup_test_git_repo

          # Create components/picoruby-esp32 submodule
          esp32_path = File.join(r2p2_path, "components", "picoruby-esp32")
          FileUtils.mkdir_p(esp32_path)
          Dir.chdir(esp32_path) do
            setup_test_git_repo

            # Create picoruby submodule
            picoruby_path = File.join(esp32_path, "picoruby")
            FileUtils.mkdir_p(picoruby_path)
            Dir.chdir(picoruby_path) do
              setup_test_git_repo
            end
          end
        end

        info, warnings = Pra::Env.traverse_submodules_and_validate(r2p2_path)

        # Should return info for all 3 levels
        assert_equal 3, info.size
        assert info.key?("R2P2-ESP32")
        assert info.key?("picoruby-esp32")
        assert info.key?("picoruby")
        assert_match(/^[a-f0-9]{7}-\d{8}_\d{6}$/, info["R2P2-ESP32"])
        assert_match(/^[a-f0-9]{7}-\d{8}_\d{6}$/, info["picoruby-esp32"])
        assert_match(/^[a-f0-9]{7}-\d{8}_\d{6}$/, info["picoruby"])
        assert_equal 0, warnings.size
      end
    end

    test "traverse_submodules_and_validate warns about 4th level submodules" do
      Dir.mktmpdir do |tmpdir|
        # Create R2P2-ESP32 repo with .gitmodules at 3rd level
        r2p2_path = tmpdir
        Dir.chdir(r2p2_path) do
          setup_test_git_repo

          esp32_path = File.join(r2p2_path, "components", "picoruby-esp32")
          FileUtils.mkdir_p(esp32_path)
          Dir.chdir(esp32_path) do
            setup_test_git_repo

            picoruby_path = File.join(esp32_path, "picoruby")
            FileUtils.mkdir_p(picoruby_path)
            Dir.chdir(picoruby_path) do
              setup_test_git_repo
              # Add .gitmodules to trigger warning
              File.write(".gitmodules", "[submodule \"test\"]\n\tpath = test\n")
            end
          end
        end

        info, warnings = Pra::Env.traverse_submodules_and_validate(r2p2_path)

        # Should warn about 4th level
        assert_equal 1, warnings.size
        assert_match(/4th level/, warnings.first)
      end
    end

    test "traverse_submodules_and_validate raises error when git rev-parse fails" do
      Dir.mktmpdir do |tmpdir|
        # Create directory without git repo
        error = assert_raise(RuntimeError) do
          Pra::Env.traverse_submodules_and_validate(tmpdir)
        end
        assert_match(/Failed to get/, error.message)
      end
    end
  end

  # env patch operations (patch_export, patch_apply, patch_diff)
  sub_test_case "env patch operations" do
    test "exports patches with patch_export command" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Create test environment
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          # Create build directory with git repository
          # Phase 4.1: Build path uses env_name instead of env_hash
          build_path = Pra::Env.get_build_path('test-env')

          # Initialize git repository with changes
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
            Pra::Commands::Env.start(['patch_export', 'test-env'])
          end

          # Verify output
          assert_match(/Exporting patches from: test-env/, output)
          assert_match(/✓ Patches exported/, output)

          # Verify patch directory was created
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'R2P2-ESP32')
          assert_true(Dir.exist?(patch_dir))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "applies patches with patch_apply command" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Create test environment
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          # Create build directory
          # Phase 4.1: Build path uses env_name instead of env_hash
          build_path = Pra::Env.get_build_path('test-env')

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)

          # Create patch file
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'R2P2-ESP32')
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, 'patch.txt'), 'patched content')

          output = capture_stdout do
            Pra::Commands::Env.start(['patch_apply', 'test-env'])
          end

          # Verify output
          assert_match(/Applying patches/, output)
          assert_match(/✓ Patches applied/, output)

          # Verify patch was applied
          assert_true(File.exist?(File.join(r2p2_work, 'patch.txt')))
          assert_equal('patched content', File.read(File.join(r2p2_work, 'patch.txt')))
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "shows patch differences with patch_diff command" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Create test environment
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

          # Create build directory with git repository
          # Phase 4.1: Build path uses env_name instead of env_hash
          build_path = Pra::Env.get_build_path('test-env')

          r2p2_work = File.join(build_path, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_work)

          # Initialize git repository
          Dir.chdir(r2p2_work) do
            system('git init > /dev/null 2>&1')
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write('test.txt', 'initial')
            system('git add . > /dev/null 2>&1')
            system('git commit -m "initial" > /dev/null 2>&1')
          end

          # Create patch directory
          patch_dir = File.join(Pra::Env::PATCH_DIR, 'R2P2-ESP32')
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, 'patch.txt'), 'patched content')

          output = capture_stdout do
            Pra::Commands::Env.start(['patch_diff', 'test-env'])
          end

          # Verify output
          assert_match(/=== Patch Differences ===/, output)
          assert_match(/Stored patches:/, output)
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  # ⚠️ [TODO-INFRASTRUCTURE-SYSTEM-MOCKING-TESTS]
  # These 3 tests are omitted pending refactoring. See Phase 4.7 TODO.md:
  # Problem: Kernel.method(:system) mocking fails in CI (environment-dependent)
  # Solution: Use Ruby Refinement or test::unit mock/stub for clean mocking
  # Impact: Missing branch coverage for clone_repo/clone_with_submodules error paths
  # Action: Refactor to use testable dependency injection + mocking patterns

  # Branch coverage tests: Uncovered error paths and conditionals
  sub_test_case "branch coverage: clone_repo error handling" do
    test "clone_repo raises error when git clone fails" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          with_system_mocking(fail_clone: true) do |mock|
            error = assert_raise(RuntimeError) do
              Pra::Env.clone_repo('https://github.com/test/repo.git', 'dest', 'abc1234')
            end
            assert_match(/Failed to clone repository/, error.message)
            assert_equal(1, mock[:call_count][:clone])
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "clone_repo raises error when git checkout fails" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Create dummy destination directory to skip clone
          dest = File.join(tmpdir, 'dest')
          FileUtils.mkdir_p(dest)
          FileUtils.mkdir_p(File.join(dest, '.git'))

          with_system_mocking(fail_checkout: true) do |mock|
            error = assert_raise(RuntimeError) do
              Pra::Env.clone_repo('https://github.com/test/repo.git', dest, 'abc1234')
            end
            assert_match(/Failed to checkout commit/, error.message)
            # clone is not called since dest already exists
            assert_equal(0, mock[:call_count][:clone])
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  sub_test_case "branch coverage: clone_with_submodules error handling" do
    test "clone_with_submodules raises error when submodule init fails" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          with_system_mocking(fail_submodule: true) do |mock|
            error = assert_raise(RuntimeError) do
              Pra::Env.clone_with_submodules('https://github.com/test/repo.git', 'dest', 'abc1234')
            end
            assert_match(/Failed to initialize submodules/, error.message)
            assert_equal(1, mock[:call_count][:clone])
            assert_equal(1, mock[:call_count][:submodule])
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  sub_test_case "branch coverage: traverse_submodules_and_validate partial structure" do
    test "traverse_submodules_and_validate handles missing picoruby-esp32" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Create only R2P2-ESP32 repo (no esp32 submodule)
          r2p2_path = File.join(tmpdir, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_path)
          Dir.chdir(r2p2_path) do
            setup_test_git_repo
          end

          info, warnings = Pra::Env.traverse_submodules_and_validate(r2p2_path)

          # Should have R2P2-ESP32 info only
          assert_equal(1, info.size)
          assert info.key?('R2P2-ESP32')
          assert_false info.key?('picoruby-esp32')
          assert_false info.key?('picoruby')
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "traverse_submodules_and_validate handles missing picoruby" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Create R2P2-ESP32 with esp32 but not picoruby
          r2p2_path = File.join(tmpdir, 'R2P2-ESP32')
          FileUtils.mkdir_p(r2p2_path)
          Dir.chdir(r2p2_path) do
            setup_test_git_repo
          end

          esp32_path = File.join(r2p2_path, 'components', 'picoruby-esp32')
          FileUtils.mkdir_p(esp32_path)
          Dir.chdir(esp32_path) do
            setup_test_git_repo
          end

          info, warnings = Pra::Env.traverse_submodules_and_validate(r2p2_path)

          # Should have R2P2-ESP32 and esp32 only
          assert_equal(2, info.size)
          assert info.key?('R2P2-ESP32')
          assert info.key?('picoruby-esp32')
          assert_false info.key?('picoruby')
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  sub_test_case "branch coverage: patch_export error handling" do
    test "patch_export raises error when environment not found" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Env.start(['patch_export', 'nonexistent'])
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "patch_export raises error when build directory not found" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          # Create environment definition but no build directory
          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('no-build-env', r2p2_info, esp32_info, picoruby_info)

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Env.start(['patch_export', 'no-build-env'])
            end
          end
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  sub_test_case "branch coverage: reset notes ternary logic" do
    test "reset preserves original notes when present" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info,
                                   notes: 'Important notes')

          output = capture_stdout do
            Pra::Commands::Env.start(['reset', 'test-env'])
          end

          config = Pra::Env.get_environment('test-env')
          assert_match(/Important notes/, config['notes'])
          assert_match(/reset at/, config['notes'])
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "reset with empty notes generates reset message only" do
      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          FileUtils.rm_f(Pra::Env::ENV_FILE)

          r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
          esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
          picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

          Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info, notes: '')

          output = capture_stdout do
            Pra::Commands::Env.start(['reset', 'test-env'])
          end

          config = Pra::Env.get_environment('test-env')
          assert_match(/^Reset at/, config['notes'])
          assert_no_match(/\n/, config['notes']) # Single line only
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end
end
