require_relative "../../test_helper"

class EnvConstantsTest < PicotorokkoTestCase
  def test_env_dir_constant_exists
    # Phase 3a: Update lib/ptrk/env.rb constants
    # ENV_DIR renamed from ptrk_env to .ptrk_env
    assert Picotorokko::Env.const_defined?(:ENV_DIR),
           "Picotorokko::Env should define ENV_DIR constant"

    assert_equal ".ptrk_env", Picotorokko::Env::ENV_DIR,
                 "Picotorokko::Env::ENV_DIR should equal '.ptrk_env'"
  end

  def test_env_name_pattern_constant_exists
    # Phase 3a: Update lib/ptrk/env.rb constants
    # ENV_NAME_PATTERN changed to YYYYMMDD_HHMMSS format (^\d+_\d+$)
    assert Picotorokko::Env.const_defined?(:ENV_NAME_PATTERN),
           "Picotorokko::Env should define ENV_NAME_PATTERN constant"

    pattern = Picotorokko::Env::ENV_NAME_PATTERN

    # Valid names: YYYYMMDD_HHMMSS format (digits_digits)
    assert_match pattern, "20251121_060114", "should match YYYYMMDD_HHMMSS format"
    assert_match pattern, "20231215_235959", "should match YYYYMMDD_HHMMSS format"
    assert_match pattern, "20000101_000000", "should match YYYYMMDD_HHMMSS format"
    assert_match pattern, "12345678_123456", "should match digits_digits format"

    # Invalid names
    assert_no_match pattern, "development", "should not match alphabetic name"
    assert_no_match pattern, "test-env", "should not match with dash"
    assert_no_match pattern, "prod_v1", "should not match alphanumeric_alphanumeric"
    assert_no_match pattern, "20251121-060114", "should not match with dash instead of underscore"
    assert_no_match pattern, "2025112", "should not match incomplete date"
    assert_no_match pattern, "20251121_", "should not match with trailing underscore"
  end

  def test_ptrk_env_directory_structure
    # Phase 3a: Verify .ptrk_env/ consolidated directory structure
    # All paths should use .ptrk_env/ prefix (hidden directory)

    # Cache directory
    expected_cache = File.join(Picotorokko::Env::PROJECT_ROOT, ".ptrk_env", ".cache")
    assert_equal expected_cache, Picotorokko::Env::CACHE_DIR,
                 "CACHE_DIR should be .ptrk_env/.cache"

    # Environment file
    expected_env_file = File.join(Picotorokko::Env::PROJECT_ROOT, ".ptrk_env", ".picoruby-env.yml")
    assert_equal expected_env_file, Picotorokko::Env::ENV_FILE,
                 "ENV_FILE should be .ptrk_env/.picoruby-env.yml"

    # Patch directory
    expected_patch = File.join(Picotorokko::Env::PROJECT_ROOT, "patch")
    assert_equal expected_patch, Picotorokko::Env::PATCH_DIR,
                 "PATCH_DIR should be patch/"
  end

  def test_build_path_uses_env_name
    # Phase 3a: Build paths should use env_name in YYYYMMDD_HHMMSS format
    # Pattern: .ptrk_env/{env_name}/ where env_name = YYYYMMDD_HHMMSS
    env_name = "20251121_060114"
    build_path = Picotorokko::Env.get_build_path(env_name)

    expected_path = File.join(Picotorokko::Env::PROJECT_ROOT, ".ptrk_build", env_name)
    assert_equal expected_path, build_path,
                 "Build path should be .ptrk_build/{env_name}"
  end

  def test_no_current_symlink_logic
    # Phase 4.1: Verify no "current" symlink is created or used
    # All operations should use explicit env_name

    # get_current_env should return nil (no implicit current)
    assert_nil Picotorokko::Env.get_current_env,
               "get_current_env should return nil (no implicit current environment)"
  end
end
