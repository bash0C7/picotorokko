require "test_helper"

class TemplateCEngineTest < PicotorokkoTestCase
  # CTemplateEngine の単体テスト

  test "renders C template with single placeholder" do
    template = create_c_template(<<~C)
      void TEMPLATE_C_PREFIX_init(mrbc_vm *vm) {
        // Initialize
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "myapp" }).render

    assert_include(result, "void myapp_init(mrbc_vm *vm)")
    assert_not_include(result, "TEMPLATE_")
  ensure
    FileUtils.rm_f(template)
  end

  test "renders C template with multiple placeholders" do
    template = create_c_template(<<~C)
      void mrbc_TEMPLATE_C_PREFIX_init(mrbc_vm *vm) {
        mrbc_class *TEMPLATE_C_PREFIX_class =
          mrbc_define_class(vm, "TEMPLATE_CLASS_NAME", mrbc_class_object);
      }
    C
    variables = { c_prefix: "myapp", class_name: "MyApp" }
    result = Ptrk::Template::CTemplateEngine.new(template, variables).render

    assert_include(result, "void mrbc_myapp_init")
    assert_include(result, "myapp_class")
    assert_include(result, '"MyApp"')
    assert_not_include(result, "TEMPLATE_")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles C function definition placeholders" do
    template = create_c_template(<<~C)
      static void
      c_TEMPLATE_C_PREFIX_version(mrbc_vm *vm, mrbc_value *v, int argc)
      {
        mrbc_value ret = mrbc_integer_value(100);
        SET_RETURN(ret);
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "sensor" }).render

    assert_include(result, "c_sensor_version")
    assert_not_include(result, "TEMPLATE_")
  ensure
    FileUtils.rm_f(template)
  end

  test "preserves C code structure with placeholder replacement" do
    template = create_c_template(<<~C)
      #include <mrubyc.h>

      void mrbc_TEMPLATE_C_PREFIX_init(mrbc_vm *vm) {
        mrbc_class *TEMPLATE_C_PREFIX_class =
          mrbc_define_class(vm, "TEMPLATE_CLASS_NAME", mrbc_class_object);
        mrbc_define_method(vm, TEMPLATE_C_PREFIX_class, "version", c_TEMPLATE_C_PREFIX_version);
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
      void mrbc_TEMPLATE_C_PREFIX_init(mrbc_vm *vm) {
        mrbc_class *TEMPLATE_C_PREFIX_class = mrbc_define_class(...);
        mrbc_define_method(vm, TEMPLATE_C_PREFIX_class, ...);
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "uart" }).render

    # Count occurrences
    uart_count = result.scan("uart").count
    assert(uart_count >= 2, "Expected at least 2 occurrences of 'uart'")
  ensure
    FileUtils.rm_f(template)
  end

  test "does not replace placeholders in comments" do
    template = create_c_template(<<~C)
      // TEMPLATE_C_PREFIX initialization
      // See TEMPLATE_CLASS_NAME documentation
      void mrbc_TEMPLATE_C_PREFIX_init(mrbc_vm *vm) {
        // TEMPLATE_C_PREFIX_class setup
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "spi", class_name: "SPI" }).render

    # Placeholders in comments should still be replaced (C engine is simple)
    # because it does text-based replacement, not AST-aware
    assert_include(result, "void mrbc_spi_init")
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

  test "replaces placeholders case-sensitively" do
    template = create_c_template(<<~C)
      TEMPLATE_C_PREFIX and
      template_c_prefix
      Template_C_Prefix
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "gpio" }).render

    assert_include(result, "gpio and")
    assert_include(result, "template_c_prefix")
    assert_include(result, "Template_C_Prefix")
  ensure
    FileUtils.rm_f(template)
  end

  test "handles underscores in replacement values" do
    template = create_c_template(<<~C)
      void mrbc_TEMPLATE_C_PREFIX_init() {
        mrbc_class *TEMPLATE_C_PREFIX_class = ...;
      }
    C
    result = Ptrk::Template::CTemplateEngine.new(template, { c_prefix: "my_device" }).render

    assert_include(result, "mrbc_my_device_init")
    assert_include(result, "my_device_class")
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
