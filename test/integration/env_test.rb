require "test_helper"
require "tmpdir"
require "fileutils"

class EnvTest < Test::Unit::TestCase
  # テスト用の一時ディレクトリ
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    # 各テスト前にENV_FILEをクリーンアップ
    FileUtils.rm_f(Picotorokko::Env::ENV_FILE)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  # YAML操作のテスト
  sub_test_case "YAML operations" do
    test "load_env_file returns empty hash when file does not exist" do
      result = Picotorokko::Env.load_env_file
      assert_equal({}, result)
    end

    test "save_env_file and load_env_file round trip" do
      data = {
        "current" => "20251121_120000",
        "environments" => {
          "20251121_120000" => {
            "R2P2-ESP32" => { "commit" => "abc1234", "timestamp" => "20250101_120000" },
            "picoruby-esp32" => { "commit" => "def5678", "timestamp" => "20250101_120000" },
            "picoruby" => { "commit" => "ghi9012", "timestamp" => "20250101_120000" },
            "notes" => "Test environment"
          }
        }
      }

      Picotorokko::Env.save_env_file(data)
      loaded = Picotorokko::Env.load_env_file

      assert_equal(data, loaded)
      assert_equal("20251121_120000", loaded["current"])
      assert_equal("abc1234", loaded["environments"]["20251121_120000"]["R2P2-ESP32"]["commit"])
    end
  end

  # 環境管理のテスト
  sub_test_case "Environment management" do
    test "get_environment returns nil for non-existent environment" do
      result = Picotorokko::Env.get_environment("non-existent")
      assert_nil(result)
    end

    test "set_environment and get_environment work together" do
      r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
      esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
      picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

      Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info, notes: "Test notes")

      env = Picotorokko::Env.get_environment("20251121_120000")
      assert_not_nil(env)
      assert_equal(r2p2_info, env["R2P2-ESP32"])
      assert_equal(esp32_info, env["picoruby-esp32"])
      assert_equal(picoruby_info, env["picoruby"])
      assert_equal("Test notes", env["notes"])
      assert_not_nil(env["created_at"])
    end
  end

  # ユーティリティメソッドのテスト
  sub_test_case "Utility methods" do
    test "generate_env_hash creates correct format" do
      r2p2 = "abc1234-20250101_120000"
      esp32 = "def5678-20250101_120000"
      picoruby = "ghi9012-20250101_120000"

      result = Picotorokko::Env.generate_env_hash(r2p2, esp32, picoruby)
      expected = "#{r2p2}_#{esp32}_#{picoruby}"

      assert_equal(expected, result)
    end

    test "get_cache_path returns correct path" do
      result = Picotorokko::Env.get_cache_path("R2P2-ESP32", "abc1234-20250101_120000")
      expected = File.join(Picotorokko::Env::CACHE_DIR, "R2P2-ESP32", "abc1234-20250101_120000")

      assert_equal(expected, result)
    end

    test "get_build_path returns correct path" do
      # Phase 4.1: Build path uses env_name instead of env_hash
      env_name = "20251121_120000"
      result = Picotorokko::Env.get_build_path(env_name)
      expected = File.join(Picotorokko::Env::PROJECT_ROOT, Picotorokko::Env::BUILD_DIR, env_name)

      assert_equal(expected, result)
    end
  end

  # Symlink操作のテスト
  sub_test_case "Symlink operations" do
    test "create_symlink creates valid symlink" do
      target = "target_dir"
      link = File.join(@tmpdir, "link")

      # targetディレクトリを作成
      FileUtils.mkdir_p(File.join(@tmpdir, target))

      Picotorokko::Env.create_symlink(target, link)

      assert_true(File.symlink?(link))
      assert_equal(target, File.readlink(link))
    end

    test "create_symlink replaces existing symlink" do
      target1 = "target1"
      target2 = "target2"
      link = File.join(@tmpdir, "link")

      FileUtils.mkdir_p(File.join(@tmpdir, target1))
      FileUtils.mkdir_p(File.join(@tmpdir, target2))

      Picotorokko::Env.create_symlink(target1, link)
      assert_equal(target1, File.readlink(link))

      Picotorokko::Env.create_symlink(target2, link)
      assert_equal(target2, File.readlink(link))
    end

    test "read_symlink returns nil for non-existent symlink" do
      result = Picotorokko::Env.read_symlink("/non/existent/path")
      assert_nil(result)
    end

    test "read_symlink returns target for valid symlink" do
      target = "target_dir"
      link = File.join(@tmpdir, "link")

      FileUtils.mkdir_p(File.join(@tmpdir, target))
      Picotorokko::Env.create_symlink(target, link)

      result = Picotorokko::Env.read_symlink(link)
      assert_equal(target, result)
    end
  end

  # compute_env_hash のテスト
  sub_test_case "compute_env_hash" do
    test "returns correct hash array for existing environment" do
      r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
      esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
      picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

      Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

      result = Picotorokko::Env.compute_env_hash("20251121_120000")
      assert_not_nil(result)

      r2p2_hash, esp32_hash, picoruby_hash, env_hash = result
      assert_equal("abc1234-20250101_120000", r2p2_hash)
      assert_equal("def5678-20250102_120000", esp32_hash)
      assert_equal("ghi9012-20250103_120000", picoruby_hash)
      assert_match(/abc1234-20250101_120000_def5678-20250102_120000_ghi9012-20250103_120000/, env_hash)
    end

    test "returns nil for non-existent environment" do
      result = Picotorokko::Env.compute_env_hash("non-existent")
      assert_nil(result)
    end
  end

  # has_submodules? のテスト
  sub_test_case "has_submodules?" do
    test "returns true when .gitmodules exists" do
      repo_dir = File.join(@tmpdir, "repo_with_submodules")
      FileUtils.mkdir_p(repo_dir)
      File.write(File.join(repo_dir, ".gitmodules"), '[submodule "test"]\n  path = test\n')

      result = Picotorokko::Env.has_submodules?(repo_dir)
      assert_true(result)
    end

    test "returns false when .gitmodules does not exist" do
      repo_dir = File.join(@tmpdir, "repo_without_submodules")
      FileUtils.mkdir_p(repo_dir)

      result = Picotorokko::Env.has_submodules?(repo_dir)
      assert_false(result)
    end
  end

  # get_timestamp のテスト (covered by integration tests in env_test.rb)

  # clone_repo エラーハンドリングのテスト
  sub_test_case "clone_repo error handling" do
    test "skips clone if directory already exists" do
      dest_path = File.join(@tmpdir, "existing_repo")
      FileUtils.mkdir_p(dest_path)

      # Should not raise error, just skip
      assert_nothing_raised do
        Picotorokko::Env.clone_repo("https://github.com/picoruby/picoruby.git", dest_path, "abc1234")
      end
    end
  end

  # traverse_submodules_and_validate のテスト (covered by integration tests)

  # read_symlink edge cases
  sub_test_case "read_symlink edge cases" do
    test "returns nil for regular file" do
      file_path = File.join(@tmpdir, "regular_file")
      File.write(file_path, "content")

      result = Picotorokko::Env.read_symlink(file_path)
      assert_nil(result)
    end
  end

  # execute_with_esp_env のテスト
  sub_test_case "execute_with_esp_env" do
    test "executes command successfully" do
      # Simple command that should succeed
      assert_nothing_raised do
        Picotorokko::Env.execute_with_esp_env("true")
      end
    end

    test "raises error when command fails" do
      assert_raise(RuntimeError) do
        Picotorokko::Env.execute_with_esp_env("false")
      end
    end

    test "executes command in specified working directory" do
      work_dir = File.join(@tmpdir, "workdir")
      FileUtils.mkdir_p(work_dir)
      marker_file = File.join(work_dir, "marker.txt")

      Picotorokko::Env.execute_with_esp_env("touch #{File.basename(marker_file)}", work_dir)
      assert_true(File.exist?(marker_file))
    end

    test "raises error when command fails in working directory" do
      work_dir = File.join(@tmpdir, "workdir")
      FileUtils.mkdir_p(work_dir)

      assert_raise(RuntimeError) do
        Picotorokko::Env.execute_with_esp_env("false", work_dir)
      end
    end
  end
end
