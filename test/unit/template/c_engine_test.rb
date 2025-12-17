require "test_helper"

class TemplateCEngineTest < PicotorokkoTestCase
  # CTemplateEngine の単体テスト

  test "renders C template with single placeholder" do
    template = create_c_template(<<~C)
      void <%= c_prefix %>_init(mrbc_vm *vm) {
        // Initialize
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "myapp" }).render

    assert_include(result, "void myapp_init(mrbc_vm *vm)")
    assert_not_include(result, "<%=")
  ensure
    FileUtils.rm_f(template)
  end

  test "renders C template with multiple placeholders" do
    template = create_c_template(<<~C)
      void mrbc_<%= c_prefix %>_init(mrbc_vm *vm) {
        mrbc_class *<%= c_prefix %>_class =
          mrbc_define_class(vm, "<%= class_name %>", mrbc_class_object);
      }
    C
    variables = { c_prefix: "myapp", class_name: "MyApp" }
    result = Ptrk::Template::CTemplateEngine.new(template, variables).render

    assert_include(result, "void mrbc_myapp_init")
    assert_include(result, "myapp_class")
    assert_include(result, '"MyApp"')
    assert_not_include(result, "<%=")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles C function definition placeholders" do
    template = create_c_template(<<~C)
      static void
      c_<%= c_prefix %>_version(mrbc_vm *vm, mrbc_value *v, int argc)
      {
        mrbc_value ret = mrbc_integer_value(100);
        SET_RETURN(ret);
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "sensor" }).render

    assert_include(result, "c_sensor_version")
    assert_not_include(result, "<%=")
  ensure
    FileUtils.rm_f(template)
  end

  test "preserves C code structure with placeholder replacement" do
    template = create_c_template(<<~C)
      #include <mrubyc.h>

      void mrbc_<%= c_prefix %>_init(mrbc_vm *vm) {
        mrbc_class *<%= c_prefix %>_class =
          mrbc_define_class(vm, "<%= class_name %>", mrbc_class_object);
        mrbc_define_method(vm, <%= c_prefix %>_class, "version", c_<%= c_prefix %>_version);
      }
    C
    variables = { c_prefix: "gpio", class_name: "GPIO" }
    result = Ptrk::Template::CTemplateEngine.new(template, variables).render

    assert_include(result, "#include <mrubyc.h>")
    assert_include(result, "mrbc_gpio_init")
    assert_include(result, "gpio_class")
    assert_include(result, '"GPIO"')
    assert_include(result, "c_gpio_version")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles multiple occurrences of same placeholder" do
    template = create_c_template(<<~C)
      void mrbc_<%= c_prefix %>_init(mrbc_vm *vm) {
        mrbc_class *<%= c_prefix %>_class = mrbc_define_class(...);
        mrbc_define_method(vm, <%= c_prefix %>_class, ...);
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "uart" }).render

    # Count occurrences
    uart_count = result.scan("uart").count
    assert(uart_count >= 2, "Expected at least 2 occurrences of 'uart'")
  ensure
    FileUtils.rm_f(template)
  end

  test "processes ERB syntax correctly" do
    template = create_c_template(<<~C)
      // Device: <%= c_prefix %>
      void mrbc_<%= c_prefix %>_init(mrbc_vm *vm) {
        // <%= class_name %> implementation
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "spi", class_name: "SPI" }).render

    assert_include(result, "// Device: spi")
    assert_include(result, "void mrbc_spi_init")
    assert_include(result, "// SPI implementation")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles empty C template" do
    template = create_c_template("")
    result = Ptrk::Template::CTemplateEngine.new(template, {}).render

    assert_equal("", result)
  ensure
    FileUtils.rm_f(template)
  end

  test "handles C template with no placeholders" do
    template = create_c_template(<<~C)
      #include <mrubyc.h>

      static void example_function() {
        // No placeholders
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "unused" }).render

    assert_include(result, "#include <mrubyc.h>")
    assert_include(result, "example_function")
    assert_not_include(result, "unused")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles ERB expressions" do
    template = create_c_template(<<~C)
      void mrbc_<%= c_prefix %>_init(mrbc_vm *vm) {
        mrbc_class *<%= c_prefix %>_class = mrbc_define_class(vm, "<%= class_name %>", mrbc_class_object);
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "gpio", class_name: "GPIO" }).render

    assert_include(result, "void mrbc_gpio_init")
    assert_include(result, "gpio_class")
    assert_include(result, '"GPIO"')
  ensure
    FileUtils.rm_f(template)
  end

  private

  def create_c_template(content)
    path = File.join(Dir.tmpdir, "template_#{SecureRandom.hex(6)}.c")
    File.write(path, content)
    path
  end
end
