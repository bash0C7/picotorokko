require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

# SystemCommandMocking is now defined in test_helper.rb

class PraCommandsDeviceTest < PraTestCase
  include SystemCommandMocking

  using SystemCommandMocking::SystemRefinement
  # device flash コマンドのテスト
  sub_test_case "device flash command" do
    test "raises error when environment not found" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)

          # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Device.start(['flash', '--env', 'nonexistent-env'])
            end
          end

          # Directory change is handled by with_fresh_project_root
        end
      end
    end

    test "raises error when no current environment is set" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)

          # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Device.start(['flash', '--env', 'current'])
            end
          end

          # Directory change is handled by with_fresh_project_root
        end
      end
    end

    test "raises error when build environment not found" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            # テスト用の環境定義を作成するが、ビルド環境は作成しない
            r2p2_info = { 'commit' => 'abc1234', 'timestamp' => '20250101_120000' }
            esp32_info = { 'commit' => 'def5678', 'timestamp' => '20250102_120000' }
            picoruby_info = { 'commit' => 'ghi9012', 'timestamp' => '20250103_120000' }

            Pra::Env.set_environment('test-env', r2p2_info, esp32_info, picoruby_info)

            assert_raise(RuntimeError) do
              capture_stdout do
                Pra::Commands::Device.start(['flash', '--env', 'test-env'])
              end
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
      end
    end

    test "shows message when flashing" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            setup_test_environment('test-env')

            with_system_mocking do |mock|
              output = capture_stdout do
                Pra::Commands::Device.start(['flash', '--env', 'test-env'])
              end

              # 出力を確認
              assert_match(/Flashing: test-env/, output)
              assert_match(/✓ Flash completed/, output)

              # コマンド実行の検証（rake flash が実行されたことを確認）
              assert_equal(1, mock[:commands_executed].count { |cmd| cmd.include?('rake flash') })
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
      end
    end
  end

  # device monitor コマンドのテスト
  sub_test_case "device monitor command" do
    test "raises error when environment not found" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)

          # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Device.start(['monitor', '--env', 'nonexistent-env'])
            end
          end

          # Directory change is handled by with_fresh_project_root
        end
      end
    end

    test "raises error when no current environment is set" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)

          # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Device.start(['monitor', '--env', 'current'])
            end
          end

          # Directory change is handled by with_fresh_project_root
        end
      end
    end

    test "shows message when monitoring" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            setup_test_environment('test-env')

            with_system_mocking do
              output = capture_stdout do
                Pra::Commands::Device.start(['monitor', '--env', 'test-env'])
              end

              # 出力を確認
              assert_match(/Monitoring: test-env/, output)
              assert_match(/Press Ctrl\+C to exit/, output)
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
      end
    end
  end

  # device build コマンドのテスト
  sub_test_case "device build command" do
    test "raises error when environment not found" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)

          # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Device.start(['build', '--env', 'nonexistent-env'])
            end
          end

          # Directory change is handled by with_fresh_project_root
        end
      end
    end

    test "shows message when building" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            setup_test_environment('test-env')

            with_system_mocking do
              output = capture_stdout do
                Pra::Commands::Device.start(['build', '--env', 'test-env'])
              end

              # 出力を確認
              assert_match(/Building: test-env/, output)
              assert_match(/✓ Build completed/, output)
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
      end
    end
  end

  # device setup_esp32 コマンドのテスト
  sub_test_case "device setup_esp32 command" do
    test "raises error when environment not found" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)

          # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Device.start(['setup_esp32', '--env', 'nonexistent-env'])
            end
          end

          # Directory change is handled by with_fresh_project_root
        end
      end
    end

    test "shows message when setting up ESP32" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            setup_test_environment('test-env')

            with_system_mocking do
              output = capture_stdout do
                Pra::Commands::Device.start(['setup_esp32', '--env', 'test-env'])
              end

              # 出力を確認
              assert_match(/Setting up ESP32: test-env/, output)
              assert_match(/✓ ESP32 setup completed/, output)
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
      end
    end
  end

  # device help/tasks コマンドのテスト
  sub_test_case "device help/tasks command" do
    test "raises error when environment not found" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)

          # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Device.start(['tasks', '--env', 'nonexistent-env'])
            end
          end

          # Directory change is handled by with_fresh_project_root
        end
      end
    end

    test "raises error when no current environment is set" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)

          # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

          assert_raise(RuntimeError) do
            capture_stdout do
              Pra::Commands::Device.start(['tasks', '--env', 'current'])
            end
          end

          # Directory change is handled by with_fresh_project_root
        end
      end
    end

    test "shows available tasks for environment" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            setup_test_environment('test-env')

            with_system_mocking do
              output = capture_stdout do
                Pra::Commands::Device.start(['tasks', '--env', 'test-env'])
              end

              # タスク一覧メッセージが出力されることを確認
              assert_match(/Available R2P2-ESP32 tasks for environment: test-env/, output)
              assert_match(/=+/, output)
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
      end
    end
  end

  # method_missing による動的Rakeタスク委譲のテスト
  sub_test_case "method_missing rake task delegation" do
    test "delegates custom_task to R2P2-ESP32 rake task" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            setup_test_environment('test-env')

            with_system_mocking do
              # custom_task が Rakefile に存在するため、method_missing で委譲される
              output = capture_stdout do
                Pra::Commands::Device.start(['custom_task', '--env', 'test-env'])
              end

              # タスク委譲メッセージが出力されることを確認
              assert_match(/Delegating to R2P2-ESP32 task: custom_task/, output)
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
      end
    end

    test "raises error when rake task does not exist" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            setup_test_environment('test-env')

            with_system_mocking(fail_rake: true) do
              assert_raise(RuntimeError) do
                capture_stdout do
                  Pra::Commands::Device.start(['nonexistent_task', '--env', 'test-env'])
                end
              end
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
      end
    end

    test "delegates rake task with explicit env" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            setup_test_environment('test-env')

            with_system_mocking do
              # custom_task が Rakefile に存在するため、method_missing で委譲される
              # 環境名は --env で明示的に指定する（暗黙のカレント環境は存在しない）
              output = capture_stdout do
                Pra::Commands::Device.start(['custom_task', '--env', 'test-env'])
              end

              # タスク委譲メッセージが出力されることを確認
              assert_match(/Delegating to R2P2-ESP32 task: custom_task/, output)
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
      end
    end

    test "does not delegate Thor internal methods" do
      # _で始まるメソッドはmethod_missingで処理されない
      device = Pra::Commands::Device.new

      # respond_to_missing? が false を返すことを確認
      assert_false(device.respond_to?(:_internal_method))
    end

    test "help command displays available tasks" do
      with_fresh_project_root do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir)
          begin
            # NOTE: tmpdir内で新しい環境を構築（前回のテスト実行の影響は受けない）

            setup_test_environment('test-env')

            with_system_mocking do
              output = capture_stdout do
                Pra::Commands::Device.start(['help', '--env', 'test-env'])
              end

              # ヘルプメッセージが表示されることを確認
              assert_match(/Available R2P2-ESP32 tasks for environment: test-env/, output)
            end

            # Directory change is handled by with_fresh_project_root
          end
        end
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

    # テスト用 Rakefile をコピー
    mock_rakefile = File.expand_path("../fixtures/R2P2-ESP32/Rakefile", __dir__)
    FileUtils.cp(mock_rakefile, File.join(r2p2_path, "Rakefile"))

    [env_name, r2p2_path]
  end

  def setup_test_environment_with_current(env_name)
    env_name, r2p2_path = setup_test_environment(env_name)

    # Set current environment for default resolution
    Pra::Env.set_current_env(env_name)

    [env_name, r2p2_path]
  end

  # parse_env_from_args のテスト
  sub_test_case "parse_env_from_args private method" do
    test "returns nil when args is empty" do
      device = Pra::Commands::Device.new
      result = device.send(:parse_env_from_args, [])
      assert_nil(result)
    end

    test "parses --env value format" do
      device = Pra::Commands::Device.new
      result = device.send(:parse_env_from_args, ['--env', 'test-env'])
      assert_equal('test-env', result)
    end

    test "parses --env=value format" do
      device = Pra::Commands::Device.new
      result = device.send(:parse_env_from_args, ['--env=test-env'])
      assert_equal('test-env', result)
    end

    test "parses --env with other arguments before" do
      device = Pra::Commands::Device.new
      result = device.send(:parse_env_from_args, ['--other', 'arg', '--env', 'test-env'])
      assert_equal('test-env', result)
    end

    test "parses --env with other arguments after" do
      device = Pra::Commands::Device.new
      result = device.send(:parse_env_from_args, ['--env', 'test-env', '--other', 'arg'])
      assert_equal('test-env', result)
    end

    test "handles --env= with empty value" do
      device = Pra::Commands::Device.new
      result = device.send(:parse_env_from_args, ['--env='])
      assert_equal('', result)
    end

    test "returns nil when --env has no following value" do
      device = Pra::Commands::Device.new
      result = device.send(:parse_env_from_args, ['--env'])
      assert_nil(result)
    end

    test "returns first --env when multiple --env present" do
      device = Pra::Commands::Device.new
      result = device.send(:parse_env_from_args, ['--env', 'first', '--env', 'second'])
      assert_equal('first', result)
    end

    test "parses --env=value with equals in value" do
      device = Pra::Commands::Device.new
      result = device.send(:parse_env_from_args, ['--env=test=env'])
      assert_equal('test=env', result)
    end
  end
end
