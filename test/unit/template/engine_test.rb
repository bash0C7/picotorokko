require "test_helper"

class TemplateEngineTest < PicotorokkoTestCase
  # Ptrk::Template::Engine インターフェーステスト

  test "Engine.render method exists" do
    assert_respond_to(Ptrk::Template::Engine, :render)
  end

  test "Engine.render returns string" do
    template_path = create_temp_ruby_template("test_template.rb")
    result = Ptrk::Template::Engine.render(template_path, {})
    assert_instance_of(String, result)
  ensure
    FileUtils.rm_f(template_path)
  end

  test "Engine.render with .rb extension uses RubyTemplateEngine" do
    template_path = create_temp_ruby_template("app.rb")
    variables = { class_name: "TestApp", version: 100 }
    result = Ptrk::Template::Engine.render(template_path, variables)

    assert_include(result, "TestApp")
    assert_include(result, "100")
    assert_not_include(result, "TEMPLATE_")
  ensure
    FileUtils.rm_f(template_path)
  end

  private

  def create_temp_ruby_template(filename)
    template_content = <<~RUBY
      class TEMPLATE_CLASS_NAME
        def version
          TEMPLATE_VERSION
        end
      end
    RUBY

    path = File.join(Dir.tmpdir, filename)
    File.write(path, template_content)
    path
  end
end
