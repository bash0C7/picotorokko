require_relative "../../test_helper"

class PicotororkoBuildConfigApplierTest < PicotorokkoTestCase
  test "insert conf.gem into empty MRuby::Build block" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
      end
    RUBY

    gems = [
      { source_type: :github, source: "ws2812", branch: "main", ref: nil },
      { source_type: :core, source: "sprintf", branch: nil, ref: nil }
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
      { source_type: :github, source: "test/gem", branch: "main", ref: nil }
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
      { source_type: :github, source: "gh/gem", branch: "main", ref: nil },
      { source_type: :core, source: "sprintf", branch: nil, ref: nil },
      { source_type: :path, source: "./local/gem", branch: nil, ref: nil },
      { source_type: :git, source: "https://example.com/gem.git", branch: "develop", ref: nil }
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
      { source_type: :github, source: "test/gem", branch: nil, ref: "abc1234" }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    assert_includes result, 'conf.gem github: "test/gem", ref: "abc1234"'
  end

  test "replace existing marker section" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
        # === BEGIN Mrbgemfile generated ===
        conf.gem github: "old/gem", branch: "old"
        # === END Mrbgemfile generated ===
      end
    RUBY

    gems = [
      { source_type: :github, source: "new/gem", branch: "new", ref: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    # Old section should be removed
    assert_not_includes result, "old/gem"
    # New section should be added
    assert_includes result, 'conf.gem github: "new/gem", branch: "new"'
    # Markers should be present
    assert_includes result, "# === BEGIN Mrbgemfile generated ==="
    assert_includes result, "# === END Mrbgemfile generated ==="
  end

  test "handle marker section in middle of existing config" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
        conf.target_name = 'picoruby'
        # === BEGIN Mrbgemfile generated ===
        conf.gem github: "old/gem"
        # === END Mrbgemfile generated ===
        conf.cc.flags = ['-O3']
      end
    RUBY

    gems = [
      { source_type: :core, source: "sprintf", branch: nil, ref: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    # Existing config should be preserved
    assert_includes result, "conf.target_name = 'picoruby'"
    assert_includes result, "conf.cc.flags = ['-O3']"
    # Old gem should be replaced
    assert_not_includes result, "old/gem"
    # New gem should be present
    assert_includes result, 'conf.gem core: "sprintf"'
  end

  test "no MRuby::Build block returns content unchanged" do
    content = <<~RUBY
      # No MRuby::Build block here
      puts "Hello World"
    RUBY

    gems = [
      { source_type: :github, source: "test/gem", branch: nil, ref: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    # Content should remain unchanged
    assert_equal content, result
  end

  test "invalid Prism syntax returns content unchanged" do
    content = "MRuby::Build.new do |conf|\n  puts 'unclosed"

    gems = [
      { source_type: :github, source: "test/gem", branch: nil, ref: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    # Content should remain unchanged on parse error
    assert_equal content, result
  end

  test "nested block depth tracking" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
        if true
          {
            key: "value"
          }
        end
      end
    RUBY

    gems = [
      { source_type: :github, source: "test/gem", branch: nil, ref: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    assert_includes result, "# === BEGIN Mrbgemfile generated ==="
    assert_includes result, 'conf.gem github: "test/gem"'
    assert_includes result, "# === END Mrbgemfile generated ==="
  end

  test "partial marker section (missing end marker)" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
        # === BEGIN Mrbgemfile generated ===
        conf.gem github: "old/gem"
      end
    RUBY

    gems = [
      { source_type: :core, source: "sprintf", branch: nil, ref: nil }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    # Content should be unchanged (no valid marker section found)
    assert_includes result, "old/gem"
    assert_includes result, 'conf.gem core: "sprintf"'
  end

  test "gem with cmake parameter" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
      end
    RUBY

    gems = [
      { source_type: :github, source: "test/gem", branch: nil, ref: nil, cmake: "target_sources(...)" }
    ]

    result = Picotorokko::BuildConfigApplier.apply(content, gems)

    assert_includes result, 'conf.gem github: "test/gem", cmake: "target_sources(...)"'
  end

  test "multiple calls produce consistent output" do
    content = <<~RUBY
      MRuby::Build.new do |conf|
      end
    RUBY

    gems = [
      { source_type: :github, source: "test/gem", branch: "main", ref: nil }
    ]

    result1 = Picotorokko::BuildConfigApplier.apply(content, gems)
    result2 = Picotorokko::BuildConfigApplier.apply(result1, gems)

    # Second application should replace marker section, not add another
    count = result2.scan("# === BEGIN Mrbgemfile generated ===").length
    assert_equal 1, count
  end
end
