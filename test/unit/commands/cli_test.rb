require_relative "../../test_helper"

class CommandsCliTest < PicotorokkoTestCase
  def test_env_command_exists
    # 2.3: Update lib/ptrk/cli.rb command registration
    # Red: Verify env, device, mrbgem, rubocop commands are registered
    # Old commands (cache, build, patch, ci) should not exist
    cli_class = Picotorokko::CLI

    # Verify new commands exist
    assert_includes cli_class.commands.keys, "env",
                    "env command should be registered"
  end

  def test_device_command_exists
    cli_class = Picotorokko::CLI
    assert_includes cli_class.commands.keys, "device",
                    "device command should be registered"
  end

  def test_mrbgems_command_exists
    cli_class = Picotorokko::CLI
    assert_includes cli_class.commands.keys, "mrbgems",
                    "mrbgems command should be registered"
  end

  def test_rubocop_command_exists
    cli_class = Picotorokko::CLI
    assert_includes cli_class.commands.keys, "rubocop",
                    "rubocop command should be registered"
  end

  def test_old_commands_do_not_exist
    # Verify old commands are NOT registered
    cli_class = Picotorokko::CLI
    assert_not_includes cli_class.commands.keys, "cache",
                        "cache command should NOT be registered"
    assert_not_includes cli_class.commands.keys, "build",
                        "build command should NOT be registered"
    assert_not_includes cli_class.commands.keys, "patch",
                        "patch command should NOT be registered"
    assert_not_includes cli_class.commands.keys, "ci",
                        "ci command should NOT be registered"
  end
end
