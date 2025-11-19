require_relative "../../test_helper"

class PicotorokkoMrbgemsDslTest < PicotorokkoTestCase
  test "parse single github gem" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem github: "ksbmyk/picoruby-ws2812", branch: "main"
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 1, gems.length
    gem = gems[0]
    assert_equal :github, gem[:source_type]
    assert_equal "ksbmyk/picoruby-ws2812", gem[:source]
    assert_equal "main", gem[:branch]
    assert_nil gem[:ref]
  end

  test "parse core gem" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem core: "sprintf"
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 1, gems.length
    gem = gems[0]
    assert_equal :core, gem[:source_type]
    assert_equal "sprintf", gem[:source]
    assert_nil gem[:branch]
    assert_nil gem[:ref]
  end

  test "parse path gem" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem path: "./local-gems/my-sensor"
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 1, gems.length
    gem = gems[0]
    assert_equal :path, gem[:source_type]
    assert_equal "./local-gems/my-sensor", gem[:source]
    assert_nil gem[:branch]
    assert_nil gem[:ref]
  end

  test "parse git gem" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem git: "https://gitlab.com/custom/gem.git", branch: "develop"
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 1, gems.length
    gem = gems[0]
    assert_equal :git, gem[:source_type]
    assert_equal "https://gitlab.com/custom/gem.git", gem[:source]
    assert_equal "develop", gem[:branch]
    assert_nil gem[:ref]
  end

  test "parse gem with ref parameter" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem github: "picoruby/stable-gem", ref: "abc1234"
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 1, gems.length
    gem = gems[0]
    assert_equal :github, gem[:source_type]
    assert_equal "picoruby/stable-gem", gem[:source]
    assert_nil gem[:branch]
    assert_equal "abc1234", gem[:ref]
  end

  test "conf.gem works as alias for gem" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem github: "test/gem1"
        conf.gem github: "test/gem2", branch: "main"
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 2, gems.length
    assert_equal "test/gem1", gems[0][:source]
    assert_equal "test/gem2", gems[1][:source]
    assert_equal "main", gems[1][:branch]
  end

  test "parse gem with cmake parameter" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem github: "sensor-gem", cmake: "target_sources(app PRIVATE src/sensor.c)"
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 1, gems.length
    gem = gems[0]
    assert_equal :github, gem[:source_type]
    assert_equal "sensor-gem", gem[:source]
    assert_nil gem[:branch]
    assert_nil gem[:ref]
    assert_equal "target_sources(app PRIVATE src/sensor.c)", gem[:cmake]
  end

  test "conditional evaluation with if" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem core: "sprintf"
        conf.gem github: "esp32-wifi" if conf.build_config_files.include?("xtensa-esp")
        conf.gem github: "rp2040-specific" if conf.build_config_files.include?("rp2040")
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 2, gems.length
    assert_equal "sprintf", gems[0][:source]
    assert_equal "esp32-wifi", gems[1][:source]
  end

  test "conditional evaluation with unless" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem core: "fiber"
        conf.gem github: "rp2040-only" unless conf.build_config_files.include?("xtensa-esp")
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 1, gems.length
    assert_equal "fiber", gems[0][:source]
  end

  test "conditional evaluation with different config name" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem github: "esp32-gem" if conf.build_config_files.include?("xtensa-esp")
        conf.gem github: "rp2040-gem" if conf.build_config_files.include?("rp2040")
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "rp2040").gems

    assert_equal 1, gems.length
    assert_equal "rp2040-gem", gems[0][:source]
  end

  test "unknown source type raises error" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem invalid_source: "some-gem"
      end
    RUBY

    assert_raise ArgumentError do
      Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems
    end
  end

  test "empty gem specification raises error" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem
      end
    RUBY

    assert_raise ArgumentError do
      Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems
    end
  end

  test "multiple gems with mixed sources" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem github: "gem1", branch: "main"
        conf.gem core: "sprintf"
        conf.gem path: "./local-gems/gem3"
        conf.gem git: "https://git.example.com/gem4.git", ref: "v1.0"
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 4, gems.length
    assert_equal :github, gems[0][:source_type]
    assert_equal "main", gems[0][:branch]
    assert_equal :core, gems[1][:source_type]
    assert_equal :path, gems[2][:source_type]
    assert_equal :git, gems[3][:source_type]
    assert_equal "v1.0", gems[3][:ref]
  end

  test "gem with both branch and ref parameters" do
    dsl_code = <<-RUBY
      mrbgems do |conf|
        conf.gem github: "multi-param-gem", branch: "develop", ref: "abc1234"
      end
    RUBY

    gems = Picotorokko::MrbgemsDSL.new(dsl_code, "xtensa-esp").gems

    assert_equal 1, gems.length
    gem = gems[0]
    assert_equal "develop", gem[:branch]
    assert_equal "abc1234", gem[:ref]
  end
end
