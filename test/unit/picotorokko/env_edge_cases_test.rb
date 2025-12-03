require_relative "../../test_helper"
require_relative "../../../lib/picotorokko/env"

module Picotorokko
  class EnvEdgeCasesTest < Test::Unit::TestCase
    def setup
      @original_dir = Dir.pwd
      @tmpdir = Dir.mktmpdir
      Dir.chdir(@tmpdir)
      Picotorokko::Env.reset_cached_root!
      FileUtils.rm_f(Picotorokko::Env::ENV_FILE)
    end

    def teardown
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@tmpdir)
    end

    # Edge cases for environment name validation
    sub_test_case "Environment name validation edge cases" do
      test "rejects name with only underscore" do
        error = assert_raise(RuntimeError) do
          Picotorokko::Env.validate_env_name!("_")
        end

        assert_include error.message, "Invalid environment name"
      end

      test "rejects name starting with underscore" do
        error = assert_raise(RuntimeError) do
          Picotorokko::Env.validate_env_name!("_20251121_060114")
        end

        assert_include error.message, "Invalid environment name"
      end

      test "rejects name with spaces" do
        error = assert_raise(RuntimeError) do
          Picotorokko::Env.validate_env_name!("20251121 060114")
        end

        assert_include error.message, "Invalid environment name"
      end

      test "rejects name with hyphen instead of underscore" do
        error = assert_raise(RuntimeError) do
          Picotorokko::Env.validate_env_name!("20251121-060114")
        end

        assert_include error.message, "Invalid environment name"
      end

      test "accepts minimum valid timestamp" do
        # Should not raise
        assert_nothing_raised do
          Picotorokko::Env.validate_env_name!("00000000_000000")
        end
      end

      test "accepts maximum realistic timestamp" do
        # Year 9999, valid timestamp
        assert_nothing_raised do
          Picotorokko::Env.validate_env_name!("99991231_235959")
        end
      end

      test "rejects empty string" do
        error = assert_raise(RuntimeError) do
          Picotorokko::Env.validate_env_name!("")
        end

        assert_include error.message, "Invalid environment name"
      end
    end

    # Edge cases for YAML file operations
    sub_test_case "YAML file operations edge cases" do
      test "handles YAML with special characters in notes" do
        r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
        esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
        picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

        special_notes = 'Test with "quotes" and \'apostrophes\' and \n newlines'

        Picotorokko::Env.set_environment(
          "20251121_120000",
          r2p2_info,
          esp32_info,
          picoruby_info,
          notes: special_notes
        )

        env = Picotorokko::Env.get_environment("20251121_120000")
        assert_equal special_notes, env["notes"]
      end

      test "handles very long environment name" do
        long_name = "99999999_999999"
        r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
        esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
        picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

        Picotorokko::Env.set_environment(long_name, r2p2_info, esp32_info, picoruby_info)

        env = Picotorokko::Env.get_environment(long_name)
        assert_not_nil env
      end

      test "handles multiple environment definitions" do
        r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
        esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
        picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

        # Create 10 environments
        10.times do |i|
          env_name = "2025010#{i}_000000"
          Picotorokko::Env.set_environment(env_name, r2p2_info, esp32_info, picoruby_info)
        end

        data = Picotorokko::Env.load_env_file
        envs = data["environments"] || {}
        assert_equal 10, envs.length
      end

      test "handles current environment tracking across saves" do
        r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
        esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
        picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

        Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)
        Picotorokko::Env.set_current_env("20251121_120000")

        current = Picotorokko::Env.get_current_env
        assert_equal "20251121_120000", current
      end

      test "removing environment clears current if it was set" do
        r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
        esp32_info = { "commit" => "def5678", "timestamp" => "20250101_120000" }
        picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250101_120000" }

        Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)
        Picotorokko::Env.set_current_env("20251121_120000")
        Picotorokko::Env.remove_environment("20251121_120000")

        current = Picotorokko::Env.get_current_env
        assert_nil current
      end
    end

    # Edge cases for path operations
    sub_test_case "Path operations edge cases" do
      test "get_cache_path with special characters in repo name" do
        repo_name = "repo-with-dashes_and_underscores"
        commit_hash = "abc1234-20250101_120000"

        path = Picotorokko::Env.get_cache_path(repo_name, commit_hash)

        assert path.include?(repo_name)
        assert path.include?(commit_hash)
      end

      test "get_build_path with various env names" do
        env_names = %w[20251121_060114 00000000_000000 99999999_235959]

        env_names.each do |env_name|
          path = Picotorokko::Env.get_build_path(env_name)
          assert path.include?(env_name)
          assert path.include?(".ptrk_build")
        end
      end

      test "read_symlink with non-symlink file" do
        test_file = File.join(@tmpdir, "regular_file.txt")
        File.write(test_file, "content")

        result = Picotorokko::Env.read_symlink(test_file)
        assert_nil result
      end

      test "create_symlink overwrites existing regular file" do
        target = File.join(@tmpdir, "target")
        link = File.join(@tmpdir, "link")

        FileUtils.mkdir_p(target)
        File.write(link, "old content")

        Picotorokko::Env.create_symlink(target, link)

        assert File.symlink?(link)
      end

      test "create_symlink with relative target" do
        FileUtils.mkdir_p(File.join(@tmpdir, "target"))
        link = File.join(@tmpdir, "link")

        Picotorokko::Env.create_symlink("target", link)

        assert File.symlink?(link)
        assert_equal "target", File.readlink(link)
      end
    end

    # Edge cases for hash computation
    sub_test_case "Hash computation edge cases" do
      test "generate_env_hash with identical hashes" do
        hash = "abc1234-20250101_120000"

        result = Picotorokko::Env.generate_env_hash(hash, hash, hash)

        assert_equal "#{hash}_#{hash}_#{hash}", result
      end

      test "compute_env_hash with missing picoruby submodule" do
        r2p2_info = { "commit" => "abc1234", "timestamp" => "20250101_120000" }
        esp32_info = { "commit" => "def5678", "timestamp" => "20250102_120000" }
        picoruby_info = { "commit" => "ghi9012", "timestamp" => "20250103_120000" }

        Picotorokko::Env.set_environment("20251121_120000", r2p2_info, esp32_info, picoruby_info)

        result = Picotorokko::Env.compute_env_hash("20251121_120000")
        assert_not_nil result

        r2p2_hash, esp32_hash, picoruby_hash, = result
        assert_equal "abc1234-20250101_120000", r2p2_hash
        assert_equal "def5678-20250102_120000", esp32_hash
        assert_equal "ghi9012-20250103_120000", picoruby_hash
      end
    end
  end
end
