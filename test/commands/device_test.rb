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
      setup_test_environment('test-env')

      with_stubbed_esp_env do
        output = capture_stdout do
          Pra::Commands::Device.start(['flash', 'test-env'])
        end

        # 出力を確認
        assert_match(/Flashing: test-env/, output)
        assert_match(/✓ Flash completed/, output)
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
      setup_test_environment('test-env')

      with_stubbed_esp_env do
        output = capture_stdout do
          Pra::Commands::Device.start(['monitor', 'test-env'])
        end

        # 出力を確認
        assert_match(/Monitoring: test-env/, output)
        assert_match(/Press Ctrl\+C to exit/, output)
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
      setup_test_environment('test-env')

      with_stubbed_esp_env do
        output = capture_stdout do
          Pra::Commands::Device.start(['build', 'test-env'])
        end

        # 出力を確認
        assert_match(/Building: test-env/, output)
        assert_match(/✓ Build completed/, output)
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
      setup_test_environment('test-env')

      with_stubbed_esp_env do
        output = capture_stdout do
          Pra::Commands::Device.start(['setup_esp32', 'test-env'])
        end

        # 出力を確認
        assert_match(/Setting up ESP32: test-env/, output)
        assert_match(/✓ ESP32 setup completed/, output)
      end
    end
  end

  # device help/tasks コマンドのテスト
  sub_test_case "device help/tasks command" do
    test "raises error when environment not found" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pra::Commands::Device.start(['tasks', 'nonexistent-env'])
        end
      end
    end

    test "raises error when no current environment is set" do
      assert_raise(RuntimeError) do
        capture_stdout do
          Pra::Commands::Device.start(['tasks'])
        end
      end
    end

    test "shows available tasks for environment" do
      setup_test_environment('test-env')

      with_stubbed_esp_env do
        output = capture_stdout do
          Pra::Commands::Device.start(['tasks', 'test-env'])
        end

        # タスク一覧メッセージが出力されることを確認
        assert_match(/Available R2P2-ESP32 tasks for environment: test-env/, output)
        assert_match(/=+/, output)
      end
    end
  end

  # method_missing による動的Rakeタスク委譲のテスト
  sub_test_case "method_missing rake task delegation" do
    test "delegates undefined command to R2P2-ESP32 rake task" do
      setup_test_environment('test-env')

      with_stubbed_esp_env do
        output = capture_stdout do
          Pra::Commands::Device.start(['custom_task', 'test-env'])
        end

        # 委譲メッセージが出力されることを確認
        assert_match(/Delegating to R2P2-ESP32 task: custom_task/, output)
      end
    end

    test "raises error when rake task does not exist" do
      setup_test_environment('test-env')

      with_failing_esp_env do
        assert_raise(SystemExit) do
          capture_stdout do
            Pra::Commands::Device.start(['nonexistent_task', 'test-env'])
          end
        end
      end
    end

    test "uses default env_name when not provided" do
      setup_test_environment_with_current('test-env')

      with_stubbed_esp_env do
        output = capture_stdout do
          Pra::Commands::Device.start(['custom_task'])
        end

        # デフォルト環境（current）が使われること
        assert_match(/Delegating to R2P2-ESP32 task: custom_task/, output)
      end
    end

    test "does not delegate Thor internal methods" do
      # _で始まるメソッドはmethod_missingで処理されない
      device = Pra::Commands::Device.new

      # respond_to_missing? が false を返すことを確認
      assert_false(device.respond_to?(:_internal_method))
    end

    test "help command displays available tasks" do
      setup_test_environment('test-env')

      with_tasks_list_esp_env do
        output = capture_stdout do
          Pra::Commands::Device.start(['help', 'test-env'])
        end

        # ヘルプメッセージが表示されることを確認
        assert_match(/Available R2P2-ESP32 tasks for environment: test-env/, output)
      end
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def setup_test_environment(env_name)
    r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
    esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
    picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

    Pra::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)

    r2p2_hash = "#{r2p2_info["commit"]}-#{r2p2_info["timestamp"]}"
    esp32_hash = "#{esp32_info["commit"]}-#{esp32_info["timestamp"]}"
    picoruby_hash = "#{picoruby_info["commit"]}-#{picoruby_info["timestamp"]}"
    env_hash = Pra::Env.generate_env_hash(r2p2_hash, esp32_hash, picoruby_hash)
    build_path = Pra::Env.get_build_path(env_hash)
    r2p2_path = File.join(build_path, "R2P2-ESP32")
    FileUtils.mkdir_p(r2p2_path)

    [env_name, r2p2_path]
  end

  def setup_test_environment_with_current(env_name)
    env_name, r2p2_path = setup_test_environment(env_name)

    current_link = File.join(Pra::Env::BUILD_DIR, "current")
    env_hash = Pra::Env.compute_env_hash(env_name).last
    FileUtils.ln_s(env_hash, current_link)
    Pra::Env.set_current_env(env_name)

    [env_name, r2p2_path]
  end

  def with_stubbed_esp_env
    original_method = Pra::Env.method(:execute_with_esp_env)
    Pra::Env.define_singleton_method(:execute_with_esp_env) do |_cmd, _path|
      # スタブ：実際の実行は避ける
    end

    begin
      yield
    ensure
      Pra::Env.define_singleton_method(:execute_with_esp_env, original_method)
    end
  end

  def with_failing_esp_env
    original_method = Pra::Env.method(:execute_with_esp_env)
    Pra::Env.define_singleton_method(:execute_with_esp_env) do |_cmd, _path|
      raise "Rake task not found"
    end

    begin
      yield
    ensure
      Pra::Env.define_singleton_method(:execute_with_esp_env, original_method)
    end
  end

  def with_tasks_list_esp_env
    original_method = Pra::Env.method(:execute_with_esp_env)
    Pra::Env.define_singleton_method(:execute_with_esp_env) do |command, _working_dir|
      return unless command == "rake -T"

      puts "rake build"
      puts "rake flash"
      puts "rake monitor"
    end

    begin
      yield
    ensure
      Pra::Env.define_singleton_method(:execute_with_esp_env, original_method)
    end
  end
end
