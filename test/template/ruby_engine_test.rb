require "test_helper"

class PrkTemplateRubyEngineTest < PraTestCase
  # RubyTemplateEngine の単体テスト

  test "renders template with single placeholder" do
    template = create_template("class TEMPLATE_CLASS_NAME; end")
    result = Ptrk::Template::RubyTemplateEngine.new(template, { class_name: "MyApp" }).render

    assert_include(result, "class MyApp")
    assert_not_include(result, "TEMPLATE_")
  ensure
    FileUtils.rm_f(template)
  end

  test "renders template with multiple placeholders" do
    template = create_template(<<~RUBY)
      class TEMPLATE_CLASS_NAME
        TEMPLATE_VERSION
      end
    RUBY
    variables = { class_name: "MyApp", version: 100 }
    result = Ptrk::Template::RubyTemplateEngine.new(template, variables).render

    assert_include(result, "MyApp")
    assert_include(result, "100")
    assert_not_include(result, "TEMPLATE_")
  ensure
    FileUtils.rm_f(template)
  end

  test "preserves comments in template" do
    template = create_template(<<~RUBY)
      # This is a comment
      class TEMPLATE_CLASS_NAME
        # Another comment
      end
    RUBY
    result = Ptrk::Template::RubyTemplateEngine.new(template, { class_name: "Test" }).render

    assert_include(result, "# This is a comment")
    assert_include(result, "# Another comment")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles placeholders in different contexts (method, constant)" do
    template = create_template(<<~RUBY)
      class TEMPLATE_CLASS_NAME
        MY_CONST = TEMPLATE_VERSION
      end
    RUBY
    variables = { class_name: "MyApp", version: 100 }
    result = Ptrk::Template::RubyTemplateEngine.new(template, variables).render

    assert_include(result, "class MyApp")
    assert_include(result, "MY_CONST = 100")
  ensure
    FileUtils.rm_f(template)
  end

  test "does not replace placeholders in string literals" do
    template = create_template(<<~RUBY)
      class TEMPLATE_CLASS_NAME
        def name
          "TEMPLATE_CLASS_NAME"
        end
      end
    RUBY
    result = Ptrk::Template::RubyTemplateEngine.new(template, { class_name: "MyApp" }).render

    assert_include(result, "class MyApp")
    # String literal is NOT replaced (it's a StringNode, not ConstantReadNode)
    assert_include(result, '"TEMPLATE_CLASS_NAME"')
  ensure
    FileUtils.rm_f(template)
  end

  test "raises error when template is invalid Ruby" do
    template = create_template("class TEMPLATE_CLASS_NAME\n  invalid ruby syntax !!!")
    engine = Ptrk::Template::RubyTemplateEngine.new(template, { class_name: "Test" })

    assert_raises(RuntimeError) do
      engine.render
    end
  ensure
    FileUtils.rm_f(template)
  end

  test "verifies output is valid Ruby after substitution" do
    template = create_template("class TEMPLATE_CLASS_NAME; end")
    # Provide invalid Ruby output (simulation - normally substitution is safe)
    result = Ptrk::Template::RubyTemplateEngine.new(template, { class_name: "ValidApp" }).render

    # Output should be valid Ruby
    parse_result = Prism.parse(result)
    assert_true(parse_result.success?, "Output should be valid Ruby")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles empty template" do
    template = create_template("")
    result = Ptrk::Template::RubyTemplateEngine.new(template, {}).render

    assert_equal("", result)
  ensure
    FileUtils.rm_f(template)
  end

  test "handles template with no placeholders" do
    template = create_template(<<~RUBY)
      class MyApp
        def version
          100
        end
      end
    RUBY
    result = Ptrk::Template::RubyTemplateEngine.new(template, { class_name: "Unused" }).render

    assert_include(result, "class MyApp")
    assert_not_include(result, "TEMPLATE_")
  ensure
    FileUtils.rm_f(template)
  end

  test "correctly identifies placeholder boundaries in mixed context" do
    template = create_template(<<~RUBY)
      class TEMPLATE_CLASS_NAME_APP
        TEMPLATE_CONSTANT
      end
    RUBY
    variables = {
      class_name_app: "MyAppV2",
      constant: 100
    }
    result = Ptrk::Template::RubyTemplateEngine.new(template, variables).render

    assert_include(result, "class MyAppV2")
    assert_include(result, "100")
  ensure
    FileUtils.rm_f(template)
  end

  private

  def create_template(content)
    path = File.join(Dir.tmpdir, "template_#{SecureRandom.hex(6)}.rb")
    File.write(path, content)
    path
  end
end
