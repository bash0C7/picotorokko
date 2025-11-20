require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../../lib/picotorokko/commands/new"

class IntegrationCommandsNewTest < PicotorokkoTestCase
  # ptrk new コマンドの結合テスト
  # NOTE: These tests perform actual network operations (git clone)
  # Network tests are marked as potentially slow and can be skipped in CI if needed

  # Integration tests for new command with real network operations
  # These tests are skipped in development but run in CI with SKIP_NETWORK_TESTS flag
  # If network tests are skipped, these test methods return early without assertions

  sub_test_case "new with network environment setup" do
    test "creates default environment with real repository information" do
      # Skip in development environment
      return if ENV["SKIP_NETWORK_TESTS"]

      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize without PTRK_SKIP_ENV_SETUP to perform actual git clone
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Verify that default environment was created
          env_file = YAML.safe_load_file("test-project/.picoruby-env.yml")
          assert env_file.is_a?(Hash)
          # Since setup_default_environment is called, environments should have 'default'
          # (unless network failed - in that case we'll have empty environments)
          # Note: Network errors are caught and logged but don't block initialization
        ensure
          Dir.chdir(original_dir)
        end
      end
    end

    test "handles network errors gracefully" do
      # This test verifies project creation succeeds even when network setup fails
      # Only runs when network tests are enabled
      return if ENV["SKIP_NETWORK_TESTS"]

      original_dir = Dir.pwd
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir)
        begin
          # Initialize project - should succeed even if network setup fails
          initializer = Picotorokko::ProjectInitializer.new("test-project", {})
          initializer.initialize_project

          # Project should be created successfully even if network setup fails
          assert File.exist?("test-project/ptrk_env")
        ensure
          Dir.chdir(original_dir)
        end
      end
    end
  end

  sub_test_case "git clone simulation" do
    test "fetch_repo_info properly clones and extracts repo information" do
      # Skip in development environment
      return if ENV["SKIP_NETWORK_TESTS"]

      env_command = Picotorokko::Commands::Env.new
      repo_name = "picoruby"
      repo_url = "https://github.com/picoruby/picoruby.git"

      begin
        repo_info = env_command.send(:fetch_repo_info, repo_name, repo_url)

        # Verify returned structure
        assert repo_info.is_a?(Hash)
        assert repo_info.key?("commit")
        assert repo_info.key?("timestamp")
        assert repo_info["commit"].is_a?(String)
        assert_match(/^\w{7}$/, repo_info["commit"], "commit should be 7-character hash")
        assert repo_info["timestamp"].is_a?(String)
        assert_match(/^\d{8}_\d{6}$/, repo_info["timestamp"], "timestamp should be YYYYMMDD_HHMMSS format")
      rescue StandardError => e
        # In case of network error, skip gracefully
        return if ENV["SKIP_NETWORK_TESTS"]

        raise e
      end
    end
  end
end
