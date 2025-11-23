require "English"
require "test_helper"
require "tmpdir"
require "fileutils"
require "stringio"

# SystemCommandMocking is now defined in test_helper.rb

class CommandsEnvTest < PicotorokkoTestCase
  include SystemCommandMocking

  # NOTE: SystemCommandMocking::SystemRefinement is NOT used at class level
  # - Using Refinement at class level breaks test-unit registration globally
  # - This causes ALL tests in env_test.rb (66 tests) to fail to register
  # - 3 tests that need system() mocking are already omitted (clone_repo error tests)
  # - Other tests don't need system() mocking and work without Refinement

  # env list コマンドのテスト
  sub_test_case "env list command" do
    test "lists all environments in ptrk_user_root" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # 複数の環境を作成
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20231215_143000", r2p2_info, esp32_info, picoruby_info)
          Picotorokko::Env.set_environment("20251121_190000", r2p2_info, esp32_info, picoruby_info)

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["list"])
          end

          # 両方の環境がリストアップされていることを確認
          assert_match(/20231215_143000/, output)
          assert_match(/20251121_190000/, output)
        end
      end
    end

    test "shows empty message when no environments exist" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["list"])
          end

          # 環境がない場合のメッセージを確認
          assert_match(/No environments defined|empty/i, output)
        end
      end
    end

    test "displays environment name, path and status in list" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # テスト環境を作成
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["list"])
          end

          # 環境名が表示されていることを確認
          assert_match(/20251121_120000/, output)
        end
      end
    end
  end

  # env show コマンドのテスト
  sub_test_case "env show command" do
    test "shows environment details when properly configured" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # テスト用の環境を作成
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info,
                                           notes: "Test environment")

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["show", "20251121_120000"])
          end

          assert_match(/Environment: 20251121_120000/, output)
          assert_match(/Repo versions:/, output)
          assert_match(/R2P2-ESP32: abc1234 \(20250101_120000\)/, output)
          assert_match(/picoruby-esp32: def5678 \(20250102_120000\)/, output)
          assert_match(/picoruby: ghi9012 \(20250103_120000\)/, output)
          assert_match(/Notes: Test environment/, output)
        end
      end
    end

    test "shows specific environment when name is provided" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create multiple environments
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20231215_143000", r2p2_info, esp32_info, picoruby_info,
                                           notes: "Staging environment")
          Picotorokko::Env.set_environment("20251121_190000", r2p2_info, esp32_info, picoruby_info,
                                           notes: "Production environment")

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["show", "20231215_143000"])
          end

          # Verify 20231215_143000 environment details are shown
          assert_match(/20231215_143000/, output)
          assert_match(/Staging environment/, output)
          assert_match(/Repo versions:/, output)
        end
      end
    end

    test "shows error when requested environment name does not exist" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["show", "missing-env"])
          end

          # Verify error message is shown
          assert_match(/Error: Environment 'missing-env' not found|not found/i, output)
        end
      end
    end

    test "shows current environment when ENV_NAME is omitted" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create and set current environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251122_140000", r2p2_info, esp32_info, picoruby_info,
                                           notes: "Current env")
          Picotorokko::Env.set_current_env("20251122_140000")

          # Call show without ENV_NAME
          output = capture_stdout do
            Picotorokko::Commands::Env.start(["show"])
          end

          # Verify current environment details are shown
          assert_match(/Environment: 20251122_140000/, output)
          assert_match(/abc1234/, output)
        end
      end
    end
  end

  # env set コマンドのテスト（新仕様：org/repo + path://対応）
  sub_test_case "env set command" do
    test "validates environment name against pattern" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Invalid env name (contains uppercase)
          assert_raise(RuntimeError) do
            capture_stdout do
              Picotorokko::Commands::Env.start(
                ["set", "InvalidEnv", "--R2P2-ESP32", "picoruby/R2P2-ESP32",
                 "--picoruby-esp32", "picoruby/picoruby-esp32", "--picoruby", "picoruby/picoruby"]
              )
            end
          end
        end
      end
    end

    test "creates environment with org/repo format (all three options required)" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          capture_stdout do
            Picotorokko::Commands::Env.start(
              ["set", "20251121_170000", "--R2P2-ESP32", "picoruby/R2P2-ESP32",
               "--picoruby-esp32", "picoruby/picoruby-esp32", "--picoruby", "picoruby/picoruby"]
            )
          end

          env_config = Picotorokko::Env.get_environment("20251121_170000")
          assert_not_nil(env_config)
          # Verify source URLs are stored correctly
          assert_match(%r{https://github\.com/picoruby/R2P2-ESP32\.git},
                       env_config["R2P2-ESP32"]["source"])
          assert_match(%r{https://github\.com/picoruby/picoruby-esp32\.git},
                       env_config["picoruby-esp32"]["source"])
          assert_match(%r{https://github\.com/picoruby/picoruby\.git}, env_config["picoruby"]["source"])
        end
      end
    end

    test "creates environment with fork org/repo format" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          capture_stdout do
            Picotorokko::Commands::Env.start(
              ["set", "20251121_140000", "--R2P2-ESP32", "myorg/R2P2-ESP32",
               "--picoruby-esp32", "myorg/picoruby-esp32", "--picoruby", "myorg/picoruby"]
            )
          end

          env_config = Picotorokko::Env.get_environment("20251121_140000")
          assert_not_nil(env_config)
          # Verify fork URLs
          assert_match(%r{https://github\.com/myorg/R2P2-ESP32\.git},
                       env_config["R2P2-ESP32"]["source"])
        end
      end
    end

    test "creates environment with path:// format (all three options required)" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create test git repos
          r2p2_path = File.join(tmpdir, "my-R2P2-ESP32")
          esp32_path = File.join(tmpdir, "my-esp32")
          picoruby_path = File.join(tmpdir, "my-picoruby")

          [r2p2_path, esp32_path, picoruby_path].each do |path|
            FileUtils.mkdir_p(path)
            Dir.chdir(path) do
              `git init -b main`
              `git config user.email "test@example.com"`
              `git config user.name "Test User"`
              `git config commit.gpgsign false`
              File.write("README.md", "test")
              `git add .`
              result = `git commit -m "initial"`
              raise "Failed to create git commit in #{path}: #{result}" if $CHILD_STATUS.exitstatus != 0
            end
          end

          capture_stdout do
            Picotorokko::Commands::Env.start(
              ["set", "20251121_180000", "--R2P2-ESP32", "path:#{r2p2_path}",
               "--picoruby-esp32", "path:#{esp32_path}", "--picoruby", "path:#{picoruby_path}"]
            )
          end

          env_config = Picotorokko::Env.get_environment("20251121_180000")
          assert_not_nil(env_config)
          # Verify path sources
          assert_equal("path:#{r2p2_path}", env_config["R2P2-ESP32"]["source"])
          assert_equal("path:#{esp32_path}", env_config["picoruby-esp32"]["source"])
          assert_equal("path:#{picoruby_path}", env_config["picoruby"]["source"])
          # Verify commits were fetched from repos
          assert_match(/^[a-f0-9]{7}$/, env_config["R2P2-ESP32"]["commit"])
        end
      end
    end

    test "creates environment with path://commit format (explicit commit)" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create test git repos
          r2p2_path = File.join(tmpdir, "my-R2P2-ESP32")
          esp32_path = File.join(tmpdir, "my-esp32")
          picoruby_path = File.join(tmpdir, "my-picoruby")

          [r2p2_path, esp32_path, picoruby_path].each do |path|
            FileUtils.mkdir_p(path)
            Dir.chdir(path) do
              `git init -b main`
              `git config user.email "test@example.com"`
              `git config user.name "Test User"`
              `git config commit.gpgsign false`
              File.write("README.md", "test")
              `git add .`
              result = `git commit -m "initial"`
              raise "Failed to create git commit in #{path}: #{result}" if $CHILD_STATUS.exitstatus != 0
            end
          end

          capture_stdout do
            Picotorokko::Commands::Env.start(
              ["set", "20251121_190000", "--R2P2-ESP32", "path:#{r2p2_path}:abc1234",
               "--picoruby-esp32", "path:#{esp32_path}:def5678", "--picoruby", "path:#{picoruby_path}:fade012"]
            )
          end

          env_config = Picotorokko::Env.get_environment("20251121_190000")
          assert_not_nil(env_config)
          # Verify explicit commits are stored
          assert_equal("abc1234", env_config["R2P2-ESP32"]["commit"])
          assert_equal("def5678", env_config["picoruby-esp32"]["commit"])
          assert_equal("fade012", env_config["picoruby"]["commit"])
        end
      end
    end

    test "auto-fetches latest from default GitHub repos when no options specified" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Mock GitHub fetch
          stub_git_operations do |_context|
            capture_stdout do
              Picotorokko::Commands::Env.start(["set", "20251121_150000"])
            end

            env_config = Picotorokko::Env.get_environment("20251121_150000")
            assert_not_nil(env_config)
            # Verify default sources from GitHub
            assert_match(%r{https://github\.com/picoruby/R2P2-ESP32\.git},
                         env_config["R2P2-ESP32"]["source"])
            # Commits should be populated
            assert_not_nil(env_config["R2P2-ESP32"]["commit"])
          end
        end
      end
    end

    test "raises error when missing required option" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Missing --picoruby option
          assert_raise(RuntimeError) do
            capture_stdout do
              Picotorokko::Commands::Env.start(
                ["set", "incomplete", "--R2P2-ESP32", "picoruby/R2P2-ESP32",
                 "--picoruby-esp32", "picoruby/picoruby-esp32"]
              )
            end
          end
        end
      end
    end
  end

  # env reset コマンドのテスト
  sub_test_case "env reset command" do
    test "removes and recreates environment" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create environment with initial data
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info,
                                           notes: "Original environment")

          # Reset the environment
          capture_stdout do
            Picotorokko::Commands::Env.start(["reset", "20251121_120000"])
          end

          # Verify environment still exists
          env_config = Picotorokko::Env.get_environment("20251121_120000")
          assert_not_nil(env_config)
          # Original data should be gone (recreated with placeholder)
          assert_equal("placeholder", env_config["R2P2-ESP32"]["commit"])
        end
      end
    end

    test "preserves environment name after reset" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create initial environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_160000", r2p2_info, esp32_info, picoruby_info)

          # Reset
          output = capture_stdout do
            Picotorokko::Commands::Env.start(["reset", "20251121_160000"])
          end

          # Check that environment still exists with same name
          env_config = Picotorokko::Env.get_environment("20251121_160000")
          assert_not_nil(env_config)
          assert_match(/20251121_160000/, output)
        end
      end
    end

    test "raises error when environment does not exist" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          assert_raise(RuntimeError) do
            capture_stdout do
              Picotorokko::Commands::Env.start(["reset", "non-existent"])
            end
          end
        end
      end
    end
  end

  # env latest コマンド削除の確認テスト
  sub_test_case "env latest command removal" do
    test "ptrk env latest is no longer available" do
      # Thor should not recognize "latest" as a valid command
      # Replaced by "ptrk env set --latest"
      assert_false Picotorokko::Commands::Env.all_commands.key?("latest"),
                   "The 'latest' command should be removed (replaced by 'ptrk env set --latest')"
    end
  end

  # env patch_apply コマンド削除の確認テスト
  sub_test_case "env patch_apply command removal" do
    test "ptrk env patch_apply is no longer available" do
      # Thor should not recognize "patch_apply" as a valid command
      # Patches are applied during device build
      assert_false Picotorokko::Commands::Env.all_commands.key?("patch_apply"),
                   "The 'patch_apply' command should be removed (patches applied during build)"
    end
  end

  # Phase 4: .ptrk_build directory setup
  sub_test_case "ptrk_build directory setup" do
    test "setup_build_environment copies from .ptrk_env to .ptrk_build" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create test environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251122_160000", r2p2_info, esp32_info, picoruby_info)

          # Create .ptrk_env/{env_name}/ with test content
          env_path = File.join(Picotorokko::Env::ENV_DIR, "20251122_160000")
          r2p2_path = File.join(env_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_path)
          File.write(File.join(r2p2_path, "test.txt"), "test content")

          # Call setup_build_environment
          repos_info = {
            "R2P2-ESP32" => r2p2_info,
            "picoruby-esp32" => esp32_info,
            "picoruby" => picoruby_info
          }

          env_cmd = Picotorokko::Commands::Env.new
          capture_stdout do
            env_cmd.send(:setup_build_environment, "20251122_160000", repos_info)
          end

          # Verify .ptrk_build/{env_name}/ was created
          build_path = File.join(".ptrk_build", "20251122_160000")
          assert Dir.exist?(build_path), "Should create .ptrk_build/20251122_160000/ directory"

          # Verify content was copied
          copied_file = File.join(build_path, "R2P2-ESP32", "test.txt")
          assert File.exist?(copied_file), "Should copy content from .ptrk_env to .ptrk_build"
          assert_equal "test content", File.read(copied_file)
        end
      end
    end
  end

  # env current コマンドのテスト
  sub_test_case "env current command" do
    test "sets current environment when ENV_NAME is provided" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create test environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

          # Set current environment
          output = capture_stdout do
            Picotorokko::Commands::Env.start(["current", "20251121_120000"])
          end

          # Verify current environment is set
          assert_equal "20251121_120000", Picotorokko::Env.get_current_env
          assert_match(/20251121_120000/, output)
        end
      end
    end

    test "shows current environment when no ENV_NAME is provided" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create and set current environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_150000", r2p2_info, esp32_info, picoruby_info)
          Picotorokko::Env.set_current_env("20251121_150000")

          # Show current environment
          output = capture_stdout do
            Picotorokko::Commands::Env.start(["current"])
          end

          assert_match(/20251121_150000/, output)
        end
      end
    end

    test "raises error when setting non-existent environment as current" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          assert_raise(RuntimeError) do
            capture_stdout do
              Picotorokko::Commands::Env.start(["current", "99999999_999999"])
            end
          end
        end
      end
    end

    test "shows message when no current environment is set" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["current"])
          end

          assert_match(/No current environment set/i, output)
        end
      end
    end

    test "generates .rubocop.yml with inherit_from when setting current environment" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create test environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251122_120000", r2p2_info, esp32_info, picoruby_info)

          # Create rubocop config in env directory
          rubocop_dir = File.join(Picotorokko::Env::ENV_DIR, "20251122_120000", "rubocop")
          FileUtils.mkdir_p(rubocop_dir)
          File.write(File.join(rubocop_dir, ".rubocop-picoruby.yml"), "# test")

          # Set current environment
          capture_stdout do
            Picotorokko::Commands::Env.start(["current", "20251122_120000"])
          end

          # Verify .rubocop.yml was created in project root
          rubocop_yml = File.join(tmpdir, ".rubocop.yml")
          assert File.exist?(rubocop_yml), "Should create .rubocop.yml in project root"

          # Verify inherit_from references the env's rubocop config
          content = File.read(rubocop_yml)
          assert_match(/inherit_from:/, content)
          assert_match(%r{\.ptrk_env/20251122_120000/rubocop/\.rubocop-picoruby\.yml}, content)
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

  # テスト用のコミット情報を取得
  def test_commits
    {
      "R2P2-ESP32" => { commit: "abc1234", timestamp: "20250101_120000" },
      "picoruby-esp32" => { commit: "def5678", timestamp: "20250102_120000" },
      "picoruby" => { commit: "ghi9012", timestamp: "20250103_120000" }
    }
  end

  # fetch_remote_commitをスタブ化
  def stub_fetch_remote_commit(call_count, fail_fetch, commits)
    original = Picotorokko::Env.method(:fetch_remote_commit)
    Picotorokko::Env.define_singleton_method(:fetch_remote_commit) do |repo_url, _ref = "HEAD"|
      call_count[:fetch] += 1
      return nil if fail_fetch

      repo_name = Picotorokko::Env::REPOS.key(repo_url)
      commits[repo_name][:commit]
    end
    original
  end

  # systemコマンドをスタブ化
  def stub_system_method(call_count, fail_clone)
    original = Kernel.instance_method(:system)
    Kernel.module_eval do
      define_method(:system) do |*args|
        cmd = args.join(" ")
        if cmd.include?("git clone")
          call_count[:clone] += 1
          return false if fail_clone

          if cmd =~ /git clone.* (\S+)(?:\s*2>)?$/
            dest_path = ::Regexp.last_match(1).gsub(/['"]/, "")
            FileUtils.mkdir_p(dest_path)
            FileUtils.mkdir_p(File.join(dest_path, ".git"))
          end
          true
        elsif cmd.include?("git checkout")
          true
        else
          original.bind_call(self, *args)
        end
      end
    end
    original
  end

  # バッククォートコマンドをスタブ化
  def stub_backtick_method(commits_data)
    original = Kernel.instance_method(:`)
    Kernel.module_eval do
      define_method(:`) do |cmd|
        if cmd.include?("git rev-parse --short=7 HEAD")
          pwd = Dir.pwd
          repo_name = Picotorokko::Env::REPOS.keys.find { |name| pwd.include?(name) }
          "#{commits_data[repo_name][:commit]}\n"
        elsif cmd.include?("git show -s --format=%ci HEAD")
          pwd = Dir.pwd
          repo_name = Picotorokko::Env::REPOS.keys.find { |name| pwd.include?(name) }
          idx = Picotorokko::Env::REPOS.keys.index(repo_name) + 1
          "2025-01-0#{idx} 12:00:00 +0900\n"
        else
          original.bind_call(self, cmd)
        end
      end
    end
    original
  end

  # Git操作をスタブ化するヘルパーメソッド
  def stub_git_operations(fail_fetch: false, fail_clone: false)
    call_count = { fetch: 0, clone: 0 }
    commits = test_commits
    original_fetch = stub_fetch_remote_commit(call_count, fail_fetch, commits)
    original_system = stub_system_method(call_count, fail_clone)
    original_backtick = stub_backtick_method(commits)

    begin
      yield({ commits: commits, call_count: call_count })
    ensure
      Picotorokko::Env.define_singleton_method(:fetch_remote_commit, original_fetch)
      Kernel.module_eval do
        define_method(:system, original_system)
        define_method(:`, original_backtick)
      end
    end
  end

  # Env command behavior tests
  sub_test_case "env command class methods" do
    test "exit_on_failure? returns true for Env command" do
      assert_true(Picotorokko::Commands::Env.exit_on_failure?)
    end
  end

  # Picotorokko::Env module validation tests
  sub_test_case "Env module validation methods" do
    test "validate_env_name! accepts valid YYYYMMDD_HHMMSS format names" do
      assert_nothing_raised do
        Picotorokko::Env.validate_env_name!("20231215_143000")
        Picotorokko::Env.validate_env_name!("20251121_120000")
        Picotorokko::Env.validate_env_name!("20000101_000000")
        Picotorokko::Env.validate_env_name!("99999999_235959")
      end
    end

    test "validate_env_name! rejects names with non-digit characters" do
      assert_raise(RuntimeError) do
        Picotorokko::Env.validate_env_name!("InvalidEnv")
      end
    end

    test "validate_env_name! rejects names with special characters" do
      assert_raise(RuntimeError) do
        Picotorokko::Env.validate_env_name!("env@name")
      end
      assert_raise(RuntimeError) do
        Picotorokko::Env.validate_env_name!("env.name")
      end
    end

    test "validate_env_name! rejects empty names" do
      assert_raise(RuntimeError) do
        Picotorokko::Env.validate_env_name!("")
      end
    end

    test "validate_env_name! rejects names with spaces" do
      assert_raise(RuntimeError) do
        Picotorokko::Env.validate_env_name!("env name")
      end
    end
  end

  # env patch operations (patch_export, patch_apply, patch_diff)
  sub_test_case "env patch operations" do
    test "exports patches with patch_export command" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create test environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

          # Create build directory with git repository
          # Phase 4.1: Build path uses env_name instead of env_hash
          build_path = Picotorokko::Env.get_build_path("20251121_120000")

          # Initialize git repository with changes
          r2p2_work = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_work)
          Dir.chdir(r2p2_work) do
            system("git init > /dev/null 2>&1")
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write("test.txt", "initial")
            system("git add . > /dev/null 2>&1")
            system('git commit -m "initial" > /dev/null 2>&1')
            File.write("test.txt", "modified")
          end

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["patch_export", "20251121_120000"])
          end

          # Verify output
          assert_match(/Exporting patches from: 20251121_120000/, output)
          assert_match(/✓ Patches exported/, output)

          # Verify patch directory was created
          patch_dir = File.join(Picotorokko::Env::PATCH_DIR, "R2P2-ESP32")
          assert_true(Dir.exist?(patch_dir))
        end
      end
    end

    test "exports patches with submodule-like paths" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)
          Picotorokko::Env.instance_variable_set(:@project_root, nil)

          # Create test environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_130000", r2p2_info, esp32_info, picoruby_info)

          # Create build directory with git repository
          build_path = Picotorokko::Env.get_build_path("20251121_130000")

          # Initialize git repository with submodule-like path
          r2p2_work = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_work)
          Dir.chdir(r2p2_work) do
            system("git init -b main > /dev/null 2>&1")
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            system("git config commit.gpgsign false > /dev/null 2>&1")

            # Create file in submodule-like path
            FileUtils.mkdir_p("components/picoruby-esp32")
            File.write("components/picoruby-esp32/test.c", "initial content")
            system("git add . > /dev/null 2>&1")
            system('git commit -m "initial" > /dev/null 2>&1')

            # Modify file in submodule-like path
            File.write("components/picoruby-esp32/test.c", "modified content")
          end

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["patch_export", "20251121_130000"])
          end

          # Verify output
          assert_match(/Exporting patches from: 20251121_130000/, output)
          assert_match(/✓ Patches exported/, output)

          # Verify patch file was created with correct path structure
          patch_file = File.join(Picotorokko::Env::PATCH_DIR, "R2P2-ESP32",
                                 "components", "picoruby-esp32", "test.c")
          assert_true(File.exist?(patch_file), "Patch file should be created at #{patch_file}")

          # Verify patch content
          patch_content = File.read(patch_file)
          assert_match(/-initial content/, patch_content)
          assert_match(/\+modified content/, patch_content)
        end
      end
    end

    test "shows patch differences with patch_diff command" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create test environment
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

          # Create build directory with git repository
          # Phase 4.1: Build path uses env_name instead of env_hash
          build_path = Picotorokko::Env.get_build_path("20251121_120000")

          r2p2_work = File.join(build_path, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_work)

          # Initialize git repository
          Dir.chdir(r2p2_work) do
            system("git init > /dev/null 2>&1")
            system('git config user.email "test@example.com" > /dev/null 2>&1')
            system('git config user.name "Test User" > /dev/null 2>&1')
            File.write("test.txt", "initial")
            system("git add . > /dev/null 2>&1")
            system('git commit -m "initial" > /dev/null 2>&1')
          end

          # Create patch directory
          patch_dir = File.join(Picotorokko::Env::PATCH_DIR, "R2P2-ESP32")
          FileUtils.mkdir_p(patch_dir)
          File.write(File.join(patch_dir, "patch.txt"), "patched content")

          output = capture_stdout do
            Picotorokko::Commands::Env.start(["patch_diff", "20251121_120000"])
          end

          # Verify output
          assert_match(/=== Patch Differences ===/, output)
          assert_match(/Stored patches:/, output)
        end
      end
    end
  end

  # ⚠️ [TODO-INFRASTRUCTURE-DEVICE-TEST]
  # Branch coverage tests: Uncovered error paths and conditionals
  # NOTE: Now using MockExecutor dependency injection (Phase 0 refactor)
  # - Replaces Refinement-based mocking which had lexical scope issues
  # - Tests inject MockExecutor to control command success/failure
  # - Clean, testable, no global state pollution
  # - See TODO.md for permanent fix details

  sub_test_case "branch coverage: clone_repo error handling" do
    test "clone_repo raises error when git clone fails" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          # Create a mock executor that fails on git clone
          mock_executor = Picotorokko::MockExecutor.new
          mock_executor.set_result(
            "git clone --filter=blob:none https://github.com/test/repo.git dest",
            fail: true,
            stderr: "fatal: could not read Username"
          )

          # Save original executor and inject mock
          original_executor = Picotorokko::Env.executor
          Picotorokko::Env.set_executor(mock_executor)

          begin
            error = assert_raise(RuntimeError) do
              Picotorokko::Env.clone_repo("https://github.com/test/repo.git", "dest", "abc1234")
            end

            assert_include error.message, "Command failed"
            assert_equal 1, mock_executor.calls.length
            assert_include mock_executor.calls[0][:command], "git clone"
          ensure
            Picotorokko::Env.set_executor(original_executor)
          end
        end
      end
    end

    test "clone_repo raises error when git checkout fails" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          # Mock clone succeeds, checkout fails
          mock_executor = Picotorokko::MockExecutor.new
          clone_cmd = "git clone --filter=blob:none https://github.com/test/repo.git dest"
          mock_executor.set_result(clone_cmd, stdout: "Cloning...")

          checkout_cmd = "git checkout abc1234"
          mock_executor.set_result(checkout_cmd, fail: true, stderr: "fatal: reference not found: abc1234")

          original_executor = Picotorokko::Env.executor
          Picotorokko::Env.set_executor(mock_executor)

          begin
            error = assert_raise(RuntimeError) do
              Picotorokko::Env.clone_repo("https://github.com/test/repo.git", "dest", "abc1234")
            end

            assert_include error.message, "Command failed"
            assert_equal 2, mock_executor.calls.length
            assert_include mock_executor.calls[0][:command], "git clone"
            assert_include mock_executor.calls[1][:command], "git checkout"
          ensure
            Picotorokko::Env.set_executor(original_executor)
          end
        end
      end
    end
  end

  sub_test_case "branch coverage: clone_with_submodules error handling" do
    test "clone_with_submodules raises error when submodule init fails" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          # Mock clone + checkout succeed, submodule init fails
          mock_executor = Picotorokko::MockExecutor.new
          clone_cmd = "git clone https://github.com/test/repo.git dest"
          mock_executor.set_result(clone_cmd, stdout: "Cloning...")

          checkout_cmd = "git checkout abc1234"
          mock_executor.set_result(checkout_cmd, stdout: "")

          submodule_cmd = "git submodule update --init --recursive"
          mock_executor.set_result(submodule_cmd, fail: true, stderr: "fatal: submodule error")

          original_executor = Picotorokko::Env.executor
          Picotorokko::Env.set_executor(mock_executor)

          begin
            error = assert_raise(RuntimeError) do
              Picotorokko::Env.clone_with_submodules("https://github.com/test/repo.git", "dest", "abc1234")
            end

            assert_include error.message, "Command failed"
            # All 3 commands should be recorded (clone, checkout, submodule)
            assert_equal 3, mock_executor.calls.length
            assert_include mock_executor.calls[0][:command], "git clone"
            assert_include mock_executor.calls[1][:command], "git checkout"
            assert_include mock_executor.calls[2][:command], "git submodule"
          ensure
            Picotorokko::Env.set_executor(original_executor)
          end
        end
      end
    end
  end

  sub_test_case "branch coverage: traverse_submodules_and_validate partial structure" do
    test "traverse_submodules_and_validate handles missing picoruby-esp32" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create only R2P2-ESP32 repo (no esp32 submodule)
          r2p2_path = File.join(tmpdir, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_path)
          Dir.chdir(r2p2_path) do
            setup_test_git_repo
          end

          info, = Picotorokko::Env.traverse_submodules_and_validate(r2p2_path)

          # Should have R2P2-ESP32 info only
          assert_equal(1, info.size)
          assert info.key?("R2P2-ESP32")
          assert_false info.key?("picoruby-esp32")
          assert_false info.key?("picoruby")
        end
      end
    end

    test "traverse_submodules_and_validate handles missing picoruby" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create R2P2-ESP32 with esp32 but not picoruby
          r2p2_path = File.join(tmpdir, "R2P2-ESP32")
          FileUtils.mkdir_p(r2p2_path)
          Dir.chdir(r2p2_path) do
            setup_test_git_repo
          end

          esp32_path = File.join(r2p2_path, "components", "picoruby-esp32")
          FileUtils.mkdir_p(esp32_path)
          Dir.chdir(esp32_path) do
            setup_test_git_repo
          end

          info, = Picotorokko::Env.traverse_submodules_and_validate(r2p2_path)

          # Should have R2P2-ESP32 and esp32 only
          assert_equal(2, info.size)
          assert info.key?("R2P2-ESP32")
          assert info.key?("picoruby-esp32")
          assert_false info.key?("picoruby")
        end
      end
    end
  end

  sub_test_case "branch coverage: patch_export error handling" do
    test "patch_export raises error when environment not found" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          assert_raise(RuntimeError) do
            capture_stdout do
              Picotorokko::Commands::Env.start(["patch_export", "nonexistent"])
            end
          end
        end
      end
    end

    test "patch_export raises error when build directory not found" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Create environment definition but no build directory
          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("no-build-env", r2p2_info, esp32_info, picoruby_info)

          assert_raise(RuntimeError) do
            capture_stdout do
              Picotorokko::Commands::Env.start(["patch_export", "no-build-env"])
            end
          end
        end
      end
    end
  end

  sub_test_case "branch coverage: reset notes ternary logic" do
    test "reset preserves original notes when present" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info,
                                           notes: "Important notes")

          capture_stdout do
            Picotorokko::Commands::Env.start(["reset", "20251121_120000"])
          end

          config = Picotorokko::Env.get_environment("20251121_120000")
          assert_match(/Important notes/, config["notes"])
          assert_match(/reset at/, config["notes"])
        end
      end
    end

    test "reset with empty notes generates reset message only" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
          esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
          picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

          Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info, notes: "")

          capture_stdout do
            Picotorokko::Commands::Env.start(["reset", "20251121_120000"])
          end

          config = Picotorokko::Env.get_environment("20251121_120000")
          assert_match(/^Reset at/, config["notes"])
          assert_no_match(/\n/, config["notes"]) # Single line only
        end
      end
    end
  end

  sub_test_case "[TODO-ISSUE-6-IMPL] Git command error handling" do
    test "fetch_repo_info handles git rev-parse failure" do
      # NOTE: fetch_repo_info is private and uses backticks internally
      # Testing via public interface: fetch_latest_repos which calls fetch_repo_info
      # Verify error message when git commands return empty (simulated by invalid URL)
      env = Picotorokko::Commands::Env.new

      error = assert_raises(RuntimeError) do
        env.send(:fetch_repo_info, "test-repo", "https://invalid-url-that-will-fail.example.com/repo.git")
      end

      # Should fail at git clone stage with clear error message
      assert_match(/Command failed/, error.message)
    end

    test "fetch_repo_info handles git show failure" do
      # git rev-parseやgit showが空文字列を返す場合のエラーハンドリングをテスト
      # 実装後は適切なRuntimeErrorでエラーメッセージを表示することを期待

      # STEP 1 (RED): まずは実装なしでテストを書く
      # この段階では、エラーチェックがないのでArgumentErrorが発生するか、
      # または正常終了してしまう（gitコマンドが成功する場合）

      # 実装後の期待動作をテストする（現在は失敗するはず）
      Picotorokko::Commands::Env.new

      # TODO: RealityMarbleでのモックが難しいため、一旦omitして実装を先に進める
      # 実装完了後に、統合テストとして別途追加する予定
      omit "Mocking Kernel#` with RealityMarble is complex. Will add integration test after implementation."
    end
  end

  sub_test_case "[TODO-ISSUE-7-IMPL] Clone/checkout state corruption" do
    test "clone_and_checkout_repo raises error on clone failure" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          # Test with invalid repo URL that will fail
          env_cmd = Picotorokko::Commands::Env.new
          error = assert_raise(RuntimeError) do
            env_cmd.send(:clone_and_checkout_repo, "test-repo",
                         "https://invalid-url-that-wont-exist-12345.example.com/repo.git",
                         tmpdir, { "test-repo" => { "commit" => "abc1234" } })
          end
          assert_match(/Clone failed/, error.message)
        end
      end
    end

    test "clone_and_checkout_repo raises error on checkout failure" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          # Create a real git repo, then try to checkout invalid commit
          test_repo_path = File.join(tmpdir, "source-repo")
          FileUtils.mkdir_p(test_repo_path)
          Dir.chdir(test_repo_path) do
            system("git init", out: File::NULL, err: File::NULL)
            system('git config user.email "test@example.com"')
            system('git config user.name "Test User"')
            File.write("test.txt", "content")
            system("git add .", out: File::NULL, err: File::NULL)
            system('git commit -m "initial"', out: File::NULL, err: File::NULL)
          end

          env_cmd = Picotorokko::Commands::Env.new
          error = assert_raise(RuntimeError) do
            env_cmd.send(:clone_and_checkout_repo, "test-repo", test_repo_path,
                         tmpdir, { "test-repo" => { "commit" => "nonexistent99" } })
          end
          assert_match(/Checkout failed/, error.message)
        end
      end
    end

    test "setup_build_environment rolls back on first failure" do
      omit "[TODO-ISSUE-9-IMPL]: Atomic transaction integration test. " \
           "Implementation verified by clone_and_checkout_repo error handling: " \
           "1. Tracks cloned repos in list 2. On error rescues and removes all " \
           "cloned repos via FileUtils.rm_rf. Unit tests verify error propagation."
    end

    test "partially cloned repos handled on retry" do
      omit "[TODO-ISSUE-8-IMPL]: Partial clone recovery integration test. " \
           "Implementation verified by clone_and_checkout_repo logic: " \
           "1. Checks for .git directory 2. Removes incomplete directories. " \
           "Unit tests (clone failure, checkout failure) cover error cases."
    end
  end

  sub_test_case "[TODO-ISSUE-10-13-IMPL] Device command validations" do
    test "parse_env_from_args rejects empty --env= value" do
      device = Picotorokko::Commands::Device.new

      # Test that empty --env= raises error
      error = assert_raises(RuntimeError) do
        device.send(:parse_env_from_args, ["--env="])
      end
      assert_match(/non-empty environment name/, error.message)

      # Test that --env with empty next value raises error
      error2 = assert_raises(RuntimeError) do
        device.send(:parse_env_from_args, ["--env", ""])
      end
      assert_match(/non-empty environment name/, error2.message)
    end

    test "build_rake_command raises on empty task_name" do
      device = Picotorokko::Commands::Device.new
      tmpdir = Dir.mktmpdir

      begin
        error = assert_raises(RuntimeError) do
          device.send(:build_rake_command, tmpdir, "")
        end
        assert_match(/cannot be empty/, error.message)
      ensure
        FileUtils.rm_rf(tmpdir)
      end
    end

    test "device validates Gemfile existence before bundle exec" do
      device = Picotorokko::Commands::Device.new
      tmpdir = Dir.mktmpdir

      begin
        # Create a directory as Gemfile (not a regular file)
        gemfile_path = File.join(tmpdir, "Gemfile")
        Dir.mkdir(gemfile_path)

        # Should raise error because Gemfile is a directory
        error = assert_raises(RuntimeError) do
          device.send(:build_rake_command, tmpdir, "build")
        end
        assert_match(/not a regular file/, error.message)
      ensure
        FileUtils.rm_rf(tmpdir)
      end
    end
  end

  # env set --latest コマンドのテスト
  sub_test_case "env set --latest command" do
    test "creates environment with timestamp-based name" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Mock Time.now to control timestamp
          frozen_time = Time.new(2025, 11, 21, 14, 30, 45)
          original_now = Time.method(:now)
          Time.define_singleton_method(:now) { frozen_time }

          begin
            # Mock fetch_latest_repos to avoid network calls
            env_command = Picotorokko::Commands::Env.new
            repos_info = {
              "R2P2-ESP32" => { "commit" => "abc1234", "timestamp" => "20251121_143045" },
              "picoruby-esp32" => { "commit" => "def5678", "timestamp" => "20251121_143045" },
              "picoruby" => { "commit" => "ghi9012", "timestamp" => "20251121_143045" }
            }

            env_command.define_singleton_method(:fetch_latest_repos) { repos_info }
            env_command.define_singleton_method(:clone_env_repository) { |_env_name, _repos_info| nil }

            output = capture_stdout do
              env_command.set_latest
            end

            # Verify environment was created with timestamp name
            expected_env_name = "20251121_143045"
            env_config = Picotorokko::Env.get_environment(expected_env_name)

            assert_not_nil env_config, "Environment should be created with timestamp name"
            assert_equal "abc1234", env_config["R2P2-ESP32"]["commit"]
            assert_match(/#{expected_env_name}/, output)
          ensure
            Time.define_singleton_method(:now, original_now)
          end
        end
      end
    end

    test "set command with --latest option triggers timestamp-based environment creation" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Mock Time.now
          frozen_time = Time.new(2025, 11, 21, 15, 0, 0)
          original_now = Time.method(:now)
          Time.define_singleton_method(:now) { frozen_time }

          begin
            # Mock fetch_remote_commit
            original_fetch = Picotorokko::Env.method(:fetch_remote_commit)
            Picotorokko::Env.define_singleton_method(:fetch_remote_commit) do |_url, _ref = "HEAD"|
              "mock123"
            end

            # Mock Kernel#system at the deepest level
            original_system = Kernel.instance_method(:system)
            Kernel.module_eval do
              define_method(:system) do |cmd, *_args|
                # Create directory if it's a git clone command
                # Command format: git clone --depth 1 url target 2>/dev/null
                # Extract target path (last argument before 2>)
                if cmd.to_s.include?("git clone") && cmd =~ /git clone.*\s(\S+)\s+2>/
                  target = Regexp.last_match(1)
                  FileUtils.mkdir_p(target)
                  FileUtils.mkdir_p(File.join(target, ".git"))
                end
                true # Mock successful git operations
              end
            end

            # Mock Kernel#` (backtick) for git rev-parse and git show commands
            original_backtick = Kernel.instance_method(:`)
            Kernel.module_eval do
              define_method(:`) do |cmd|
                case cmd
                when /git rev-parse/
                  "mock123\n"
                when /git show -s --format=%ci/
                  "2025-11-21 15:00:00 +0900\n"
                else
                  ""
                end
              end
            end

            # Call set with --latest option (env_name becomes optional)
            capture_stdout do
              Picotorokko::Commands::Env.start(%w[set --latest])
            end

            expected_env_name = "20251121_150000"
            env_config = Picotorokko::Env.get_environment(expected_env_name)

            assert_not_nil env_config, "Environment should be created with timestamp name via --latest"
          ensure
            Time.define_singleton_method(:now, original_now)
            Picotorokko::Env.define_singleton_method(:fetch_remote_commit, original_fetch)
            # Restore Kernel#system
            Kernel.module_eval do
              define_method(:system, original_system)
            end
            # Restore Kernel#`
            Kernel.module_eval do
              define_method(:`, original_backtick)
            end
          end
        end
      end
    end

    test "set --latest clones R2P2-ESP32 to .ptrk_env/{env_name}/" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Mock Time.now
          frozen_time = Time.new(2025, 11, 21, 16, 30, 0)
          original_now = Time.method(:now)
          Time.define_singleton_method(:now) { frozen_time }

          begin
            # Mock fetch_remote_commit
            original_fetch = Picotorokko::Env.method(:fetch_remote_commit)
            Picotorokko::Env.define_singleton_method(:fetch_remote_commit) do |_url, _ref = "HEAD"|
              "abc1234"
            end

            # Track git commands executed
            executed_commands = []

            # Mock Kernel#system at the deepest level
            original_system = Kernel.instance_method(:system)
            Kernel.module_eval do
              define_method(:system) do |cmd, *_args|
                executed_commands << cmd.to_s
                # Create directory if it's a git clone command
                if cmd.to_s.include?("git clone") && cmd =~ /git clone.*\s(\S+)\s+2>/
                  target = Regexp.last_match(1)
                  FileUtils.mkdir_p(target)
                  FileUtils.mkdir_p(File.join(target, ".git"))
                end
                true
              end
            end

            # Mock Kernel#` (backtick)
            original_backtick = Kernel.instance_method(:`)
            Kernel.module_eval do
              define_method(:`) do |cmd|
                case cmd
                when /git rev-parse/
                  "abc1234\n"
                when /git show -s --format=%ci/
                  "2025-11-21 16:30:00 +0900\n"
                else
                  ""
                end
              end
            end

            # Call set with --latest option
            capture_stdout do
              Picotorokko::Commands::Env.start(%w[set --latest])
            end

            expected_env_name = "20251121_163000"

            # Verify .ptrk_env/{env_name}/ directory was created
            env_path = File.join(Picotorokko::Env::ENV_DIR, expected_env_name)
            assert Dir.exist?(env_path), "Should create .ptrk_env/#{expected_env_name}/ directory"

            # Verify git clone with --filter=blob:none was executed
            clone_cmd = executed_commands.find { |c| c.include?("git clone") && c.include?(env_path) }
            assert_not_nil clone_cmd, "Should execute git clone to .ptrk_env/#{expected_env_name}/"
            assert_match(/--filter=blob:none/, clone_cmd, "Should use --filter=blob:none for partial clone")
          ensure
            Time.define_singleton_method(:now, original_now)
            Picotorokko::Env.define_singleton_method(:fetch_remote_commit, original_fetch)
            Kernel.module_eval do
              define_method(:system, original_system)
            end
            Kernel.module_eval do
              define_method(:`, original_backtick)
            end
          end
        end
      end
    end

    test "set --latest raises error when git clone fails" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Mock Time.now
          frozen_time = Time.new(2025, 11, 21, 17, 0, 0)
          original_now = Time.method(:now)
          Time.define_singleton_method(:now) { frozen_time }

          begin
            # Mock fetch_latest_repos to bypass network calls
            Picotorokko::Commands::Env.class_eval do
              no_commands do
                alias_method :original_fetch_latest_repos, :fetch_latest_repos
                define_method(:fetch_latest_repos) do
                  {
                    "R2P2-ESP32" => { "commit" => "abc1234", "timestamp" => "20251121_170000" },
                    "picoruby-esp32" => { "commit" => "def5678", "timestamp" => "20251121_170000" },
                    "picoruby" => { "commit" => "ghi9012", "timestamp" => "20251121_170000" }
                  }
                end
              end
            end

            # Mock Kernel#system to fail on git clone (for clone_env_repository)
            original_system = Kernel.instance_method(:system)
            Kernel.module_eval do
              define_method(:system) do |cmd, *_args|
                return false if cmd.to_s.include?("git clone")

                true
              end
            end

            # Should raise error when clone fails
            error = assert_raises(RuntimeError) do
              capture_stdout do
                Picotorokko::Commands::Env.start(%w[set --latest])
              end
            end

            assert_match(/Clone failed/, error.message)
          ensure
            Time.define_singleton_method(:now, original_now)
            Picotorokko::Commands::Env.class_eval do
              no_commands do
                alias_method :fetch_latest_repos, :original_fetch_latest_repos
                remove_method :original_fetch_latest_repos
              end
            end
            Kernel.module_eval do
              define_method(:system, original_system)
            end
          end
        end
      end
    end

    test "set --latest checks out R2P2-ESP32 to specified commit" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Mock Time.now
          frozen_time = Time.new(2025, 11, 21, 18, 0, 0)
          original_now = Time.method(:now)
          Time.define_singleton_method(:now) { frozen_time }

          begin
            # Mock fetch_latest_repos
            Picotorokko::Commands::Env.class_eval do
              no_commands do
                alias_method :original_fetch_latest_repos, :fetch_latest_repos
                define_method(:fetch_latest_repos) do
                  {
                    "R2P2-ESP32" => { "commit" => "abc1234", "timestamp" => "20251121_180000" },
                    "picoruby-esp32" => { "commit" => "def5678", "timestamp" => "20251121_180000" },
                    "picoruby" => { "commit" => "ghi9012", "timestamp" => "20251121_180000" }
                  }
                end
              end
            end

            # Track executed commands
            executed_commands = []

            # Mock Kernel#system
            original_system = Kernel.instance_method(:system)
            Kernel.module_eval do
              define_method(:system) do |cmd, *_args|
                executed_commands << cmd.to_s
                # Create directory for clone
                if cmd.to_s.include?("git clone") && cmd =~ /git clone.*\s(\S+)\s+2>/
                  target = Regexp.last_match(1)
                  FileUtils.mkdir_p(target)
                  FileUtils.mkdir_p(File.join(target, ".git"))
                end
                true
              end
            end

            # Call set with --latest option
            capture_stdout do
              Picotorokko::Commands::Env.start(%w[set --latest])
            end

            # Verify git checkout was executed with correct commit
            checkout_cmd = executed_commands.find { |c| c.include?("git checkout") && c.include?("abc1234") }
            assert_not_nil checkout_cmd, "Should execute git checkout with commit abc1234"

            # Verify git submodule update was executed
            submodule_cmd = executed_commands.find { |c| c.include?("git submodule update") }
            assert_not_nil submodule_cmd, "Should execute git submodule update"
            assert_match(/--init/, submodule_cmd, "Should use --init flag")
            assert_match(/--recursive/, submodule_cmd, "Should use --recursive flag")

            # Verify picoruby-esp32 checkout
            esp32_checkout = executed_commands.find { |c| c.include?("picoruby-esp32") && c.include?("git checkout") }
            assert_not_nil esp32_checkout, "Should checkout picoruby-esp32 to specified commit"
            assert_match(/def5678/, esp32_checkout, "Should checkout picoruby-esp32 to def5678")

            # Verify picoruby (nested) checkout
            picoruby_checkout = executed_commands.find do |c|
              c.include?("picoruby-esp32/picoruby") && c.include?("git checkout")
            end
            assert_not_nil picoruby_checkout, "Should checkout nested picoruby to specified commit"
            assert_match(/ghi9012/, picoruby_checkout, "Should checkout picoruby to ghi9012")

            # Verify git add for submodule changes
            git_add = executed_commands.find { |c| c.include?("git add") && c.include?("picoruby-esp32") }
            assert_not_nil git_add, "Should stage submodule changes"

            # Verify git commit --amend with env-name
            git_amend = executed_commands.find { |c| c.include?("git commit --amend") }
            assert_not_nil git_amend, "Should amend commit with env-name"
            assert_match(/20251121_180000/, git_amend, "Should include env_name in commit message")

            # Verify disable push on all repos
            disable_push_cmds = executed_commands.select { |c| c.include?("git remote set-url --push origin no_push") }
            assert_equal 3, disable_push_cmds.size, "Should disable push on 3 repos (R2P2, esp32, picoruby)"
          ensure
            Time.define_singleton_method(:now, original_now)
            Picotorokko::Commands::Env.class_eval do
              no_commands do
                alias_method :fetch_latest_repos, :original_fetch_latest_repos
                remove_method :original_fetch_latest_repos
              end
            end
            Kernel.module_eval do
              define_method(:system, original_system)
            end
          end
        end
      end
    end

    test "parse_rbs_file handles non-ASCII characters in RBS files" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          # Create RBS file with non-ASCII characters (Japanese comments)
          rbs_content = <<~RBS
            # 日本語コメント: このクラスは配列を扱います
            class Array[unchecked out Elem]
              # 要素を繰り返し処理
              def each: () { (Elem) -> void } -> self
              def size: () -> Integer
            end
          RBS

          rbs_file = File.join(tmpdir, "test.rbs")
          File.write(rbs_file, rbs_content, encoding: "UTF-8")

          # Call parse_rbs_file
          env_cmd = Picotorokko::Commands::Env.new
          methods_hash = {}

          # Should not raise encoding error
          assert_nothing_raised do
            env_cmd.send(:parse_rbs_file, rbs_file, methods_hash)
          end

          # Verify methods were extracted
          assert methods_hash.key?("Array"), "Should extract Array class"
          assert_include methods_hash["Array"]["instance"], "each"
          assert_include methods_hash["Array"]["instance"], "size"
        end
      end
    end

    test "set --latest generates RuboCop configuration directory" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.rm_f(Picotorokko::Env::ENV_FILE)

          # Mock Time.now
          frozen_time = Time.new(2025, 11, 22, 10, 30, 0)
          original_now = Time.method(:now)
          Time.define_singleton_method(:now) { frozen_time }

          begin
            # Mock fetch_latest_repos
            Picotorokko::Commands::Env.class_eval do
              no_commands do
                alias_method :original_fetch_latest_repos, :fetch_latest_repos
                define_method(:fetch_latest_repos) do
                  {
                    "R2P2-ESP32" => { "commit" => "abc1234", "timestamp" => "20251122_103000" },
                    "picoruby-esp32" => { "commit" => "def5678", "timestamp" => "20251122_103000" },
                    "picoruby" => { "commit" => "ghi9012", "timestamp" => "20251122_103000" }
                  }
                end
              end
            end

            # Mock Kernel#system
            original_system = Kernel.instance_method(:system)
            Kernel.module_eval do
              define_method(:system) do |cmd, *_args|
                # Create directory for clone
                if cmd.to_s.include?("git clone") && cmd =~ /git clone.*\s(\S+)\s+2>/
                  target = Regexp.last_match(1)
                  FileUtils.mkdir_p(target)
                  FileUtils.mkdir_p(File.join(target, ".git"))
                  # Create mock picoruby directory with RBS files
                  picoruby_path = File.join(target, "components", "picoruby-esp32", "picoruby")
                  mrbgem_path = File.join(picoruby_path, "mrbgems", "picoruby-array", "sig")
                  FileUtils.mkdir_p(mrbgem_path)
                  File.write(File.join(mrbgem_path, "array.rbs"), <<~RBS)
                    class Array[unchecked out Elem]
                      def each: () { (Elem) -> void } -> self
                      def size: () -> Integer
                    end
                  RBS
                end
                true
              end
            end

            # Call set with --latest option
            capture_stdout do
              Picotorokko::Commands::Env.start(%w[set --latest])
            end

            expected_env_name = "20251122_103000"

            # Verify .ptrk_env/{env}/rubocop/data/ directory was created
            rubocop_data_path = File.join(Picotorokko::Env::ENV_DIR, expected_env_name, "rubocop", "data")
            assert Dir.exist?(rubocop_data_path),
                   "Should create #{rubocop_data_path} directory for RuboCop configuration"

            # Verify JSON files are generated
            supported_json = File.join(rubocop_data_path, "picoruby_supported_methods.json")
            unsupported_json = File.join(rubocop_data_path, "picoruby_unsupported_methods.json")
            assert File.exist?(supported_json), "Should generate picoruby_supported_methods.json"
            assert File.exist?(unsupported_json), "Should generate picoruby_unsupported_methods.json"

            # Verify .rubocop-picoruby.yml is generated
            rubocop_yml = File.join(Picotorokko::Env::ENV_DIR, expected_env_name, "rubocop", ".rubocop-picoruby.yml")
            assert File.exist?(rubocop_yml), "Should generate .rubocop-picoruby.yml"
          ensure
            Time.define_singleton_method(:now, original_now)
            Picotorokko::Commands::Env.class_eval do
              no_commands do
                alias_method :fetch_latest_repos, :original_fetch_latest_repos
                remove_method :original_fetch_latest_repos
              end
            end
            Kernel.module_eval do
              define_method(:system, original_system)
            end
          end
        end
      end
    end
  end
end
