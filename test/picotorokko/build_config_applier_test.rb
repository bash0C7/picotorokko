require_relative "../test_helper"

class PicotororkoBuildConfigApplierTest < PraTestCase
  test "insert conf.gem into empty MRuby::Build block" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
      end
    RUBY

    gems = [
      { source_type: :github, source: "ws2812", branch: "main", ref: nil, cmake: nil },
      { source_type: :core, source: "sprintf", branch: nil, ref: nil, cmake: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    assert_includes result, "# === BEGIN Mrbgemfile generated ==="
    assert_includes result, "# === END Mrbgemfile generated ==="
    assert_includes result, 'conf.gem github: "ws2812", branch: "main"'
    assert_includes result, 'conf.gem core: "sprintf"'
  end

  test "insert conf.gem after existing config" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
        conf.target_name = 'picoruby'
        conf.cc.flags = ['-g', '-O3']
      end
    RUBY

    gems = [
      { source_type: :github, source: "test/gem", branch: "main", ref: nil, cmake: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    assert_includes result, "conf.target_name = 'picoruby'"
    assert_includes result, "# === BEGIN Mrbgemfile generated ==="
    assert_includes result, 'conf.gem github: "test/gem", branch: "main"'
    assert_includes result, "# === END Mrbgemfile generated ==="
  end

  test "insert with all parameter types" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
      end
    RUBY

    gems = [
      { source_type: :github, source: "gh/gem", branch: "main", ref: nil, cmake: nil },
      { source_type: :core, source: "sprintf", branch: nil, ref: nil, cmake: nil },
      { source_type: :path, source: "./local/gem", branch: nil, ref: nil, cmake: nil },
      { source_type: :git, source: "https://example.com/gem.git", branch: "develop", ref: nil, cmake: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    assert_includes result, 'conf.gem github: "gh/gem", branch: "main"'
    assert_includes result, 'conf.gem core: "sprintf"'
    assert_includes result, 'conf.gem path: "./local/gem"'
    assert_includes result, 'conf.gem git: "https://example.com/gem.git", branch: "develop"'
  end

  test "insert with ref parameter" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
      end
    RUBY

    gems = [
      { source_type: :github, source: "test/gem", branch: nil, ref: "abc1234", cmake: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    assert_includes result, 'conf.gem github: "test/gem", ref: "abc1234"'
  end
end
