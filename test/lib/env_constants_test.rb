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
end
