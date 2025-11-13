require_relative "../test_helper"

class PicotorokkoMrbgemsDslTest < PraTestCase
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
    assert_nil gem[:cmake]
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
    assert_nil gem[:cmake]
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
    assert_nil gem[:cmake]
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
    assert_nil gem[:cmake]
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
    assert_nil gem[:cmake]
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
end
