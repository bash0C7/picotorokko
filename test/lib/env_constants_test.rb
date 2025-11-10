require_relative "../test_helper"

class EnvConstantsTest < PraTestCase
  def test_env_dir_constant_exists
    # 2.2: Update lib/ptrk/env.rb constants
    # Red: Verify ENV_DIR constant exists and is "ptrk_env"
    assert Pra::Env.const_defined?(:ENV_DIR),
           "Pra::Env should define ENV_DIR constant"

    assert_equal "ptrk_env", Pra::Env::ENV_DIR,
                 "Pra::Env::ENV_DIR should equal 'ptrk_env'"
  end

  def test_env_name_pattern_constant_exists
    # 2.2: Update lib/ptrk/env.rb constants
    # Red: Verify ENV_NAME_PATTERN constant exists and matches valid env names
    assert Pra::Env.const_defined?(:ENV_NAME_PATTERN),
           "Pra::Env should define ENV_NAME_PATTERN constant"

    pattern = Pra::Env::ENV_NAME_PATTERN

    # Valid names
    assert_match pattern, "development", "should match 'development'"
    assert_match pattern, "staging", "should match 'staging'"
    assert_match pattern, "test-env", "should match 'test-env'"
    assert_match pattern, "prod_v1", "should match 'prod_v1'"
    assert_match pattern, "a1b2c3", "should match 'a1b2c3'"

    # Invalid names
    assert_no_match pattern, "Dev", "should not match uppercase 'Dev'"
    assert_no_match pattern, "test env", "should not match with space"
    assert_no_match pattern, "test/env", "should not match with slash"
    assert_no_match pattern, "test.env", "should not match with dot"
  end

  def test_ptrk_env_directory_structure
    # Phase 4.1: Verify ptrk_env/ consolidated directory structure
    # All paths should use ptrk_env/ prefix

    # Cache directory
    expected_cache = File.join(Pra::Env::PROJECT_ROOT, "ptrk_env", ".cache")
    assert_equal expected_cache, Pra::Env::CACHE_DIR,
                 "CACHE_DIR should be ptrk_env/.cache"

    # Environment file
    expected_env_file = File.join(Pra::Env::PROJECT_ROOT, "ptrk_env", ".picoruby-env.yml")
    assert_equal expected_env_file, Pra::Env::ENV_FILE,
                 "ENV_FILE should be ptrk_env/.picoruby-env.yml"

    # Patch directory
    expected_patch = File.join(Pra::Env::PROJECT_ROOT, "ptrk_env", "patch")
    assert_equal expected_patch, Pra::Env::PATCH_DIR,
                 "PATCH_DIR should be ptrk_env/patch"
  end

  def test_build_path_uses_env_name
    # Phase 4.1: Build paths should use env_name instead of env_hash
    # Pattern: ptrk_env/{env_name}/ instead of build/{env_hash}/
    env_name = "test-env"
    build_path = Pra::Env.get_build_path(env_name)

    expected_path = File.join(Pra::Env::PROJECT_ROOT, "ptrk_env", env_name)
    assert_equal expected_path, build_path,
                 "Build path should be ptrk_env/{env_name}"
  end

  def test_no_current_symlink_logic
    # Phase 4.1: Verify no "current" symlink is created or used
    # All operations should use explicit env_name

    # get_current_env should return nil (no implicit current)
    assert_nil Pra::Env.get_current_env,
               "get_current_env should return nil (no implicit current environment)"
  end
end
