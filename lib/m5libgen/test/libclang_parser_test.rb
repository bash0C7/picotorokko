# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

# Test M5LibGen::LibClangParser
class LibClangParserTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir("m5libgen_test")
    @test_header = File.join(@tmpdir, "test.h")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_initialize
    create_simple_header
    parser = M5LibGen::LibClangParser.new(@test_header)
    assert_equal @test_header, parser.header_path
  end

  def test_parse_simple_class
    create_simple_header
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    assert_equal 1, classes.length
    assert_equal "SimpleClass", classes[0][:name]
  end

  def test_extract_class_with_methods
    create_header_with_methods
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    assert_equal 1, classes.length
    klass = classes[0]
    assert_equal "Calculator", klass[:name]
    assert_kind_of Array, klass[:methods]
    assert klass[:methods].length.positive?
  end

  def test_extract_method_names
    create_header_with_methods
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    method_names = klass[:methods].map { |m| m[:name] }
    assert_includes method_names, "add"
    assert_includes method_names, "subtract"
  end

  def test_extract_method_return_types
    create_header_with_methods
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    add_method = klass[:methods].find { |m| m[:name] == "add" }
    assert_equal "int", add_method[:return_type]
  end

  def test_extract_method_parameters
    create_header_with_methods
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    add_method = klass[:methods].find { |m| m[:name] == "add" }
    assert_equal 2, add_method[:parameters].length
    assert_equal "int", add_method[:parameters][0][:type]
    assert_equal "a", add_method[:parameters][0][:name]
  end

  def test_raises_error_if_header_does_not_exist
    assert_raise(M5LibGen::LibClangParser::ParseError) do
      M5LibGen::LibClangParser.new("/nonexistent/file.h")
    end
  end

  def test_extract_static_method
    create_header_with_static_method
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    static_method = klass[:methods].find { |m| m[:name] == "getInstance" }
    assert_equal true, static_method[:is_static]
  end

  def test_extract_const_method
    create_header_with_const_method
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    const_method = klass[:methods].find { |m| m[:name] == "getValue" }
    assert_equal true, const_method[:is_const]
  end

  def test_extract_virtual_method
    create_header_with_virtual_method
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    virtual_method = klass[:methods].find { |m| m[:name] == "draw" }
    assert_equal true, virtual_method[:is_virtual]
  end

  def test_extract_inline_method
    create_header_with_inline_method
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    inline_method = klass[:methods].find { |m| m[:name] == "wasClicked" }
    assert_not_nil inline_method, "Inline method wasClicked should be extracted"
    assert_equal "bool", inline_method[:return_type]
    assert_equal true, inline_method[:is_const]
  end

  def test_extract_multiple_inline_methods
    create_header_with_multiple_inline_methods
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    assert_equal "Button", klass[:name]

    method_names = klass[:methods].map { |m| m[:name] }
    assert_includes method_names, "wasClicked", "Should extract wasClicked"
    assert_includes method_names, "wasPressed", "Should extract wasPressed"
    assert_includes method_names, "isHolding", "Should extract isHolding"
    assert klass[:methods].length >= 3, "Should extract at least 3 inline methods"
  end

  def test_skip_preprocessor_directives
    create_header_with_preprocessor_directives
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    assert_equal "ConfigurableClass", klass[:name]

    # Should extract real methods only
    method_names = klass[:methods].map { |m| m[:name] }
    assert_includes method_names, "realMethod", "Should extract realMethod"
    assert_includes method_names, "update", "Should extract update method"

    # Should NOT extract function calls as methods
    assert_not_includes method_names, "SDL_Delay", "Should not extract SDL_Delay as method"
    assert_not_includes method_names, "delay", "Should not extract delay as method"

    # All extracted methods should have valid return types (not preprocessor keywords)
    klass[:methods].each do |method|
      refute_match(/^(if|ifdef|ifndef|else|elif|endif|define|undef|include|pragma|return)$/,
                   method[:return_type],
                   "Return type should not be preprocessor directive: #{method[:return_type]} for #{method[:name]}")
    end
  end

  def test_extract_only_valid_return_types
    create_header_with_preprocessor_directives
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]

    # Verify all return types are valid C++ types
    klass[:methods].each do |method|
      assert_match(/^(void|bool|int|float|double|char|return\s+\w+|\w+[\w\s*&:<>,]+)$/,
                   method[:return_type],
                   "Invalid return type: #{method[:return_type]} for method #{method[:name]}")
    end
  end

  # Issue 1-1: Parameter name sanitization
  def test_sanitize_parameter_names_with_member_access
    create_header_with_struct_member_parameter
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes.find { |c| c[:name] == "Display" }
    assert_not_nil klass, "Should extract Display class"

    dsp_method = klass[:methods].find { |m| m[:name] == "configure" }
    assert_not_nil dsp_method, "Should extract configure method"

    # Parameter names should not contain '.' or '->' operators
    dsp_method[:parameters].each do |param|
      refute_match(/\./, param[:name], "Parameter name should not contain '.': #{param[:name]}")
      refute_match(/->/, param[:name], "Parameter name should not contain '->': #{param[:name]}")
    end

    # Should have valid parameter name (either original or sanitized to param_N)
    assert_match(/^(cfg|param_\d+)$/, dsp_method[:parameters][0][:name],
                 "Parameter name should be 'cfg' or sanitized to 'param_0'")
  end

  def test_generate_generic_names_for_empty_parameter_names
    create_header_with_unnamed_parameters
    parser = M5LibGen::LibClangParser.new(@test_header)
    classes = parser.extract_classes

    klass = classes[0]
    method = klass[:methods].find { |m| m[:name] == "process" }
    assert_not_nil method

    # All parameters should have valid names (not empty)
    method[:parameters].each_with_index do |param, idx|
      refute_empty param[:name], "Parameter #{idx} should have a name"
      # Should be generic name if original was empty
      assert_match(/^(param_\d+|\w+)$/, param[:name],
                   "Parameter name should be valid identifier")
    end
  end

  private

  def create_simple_header
    File.write(@test_header, <<~CPP)
      class SimpleClass {
      public:
        void doSomething();
      };
    CPP
  end

  def create_header_with_methods
    File.write(@test_header, <<~CPP)
      class Calculator {
      public:
        int add(int a, int b);
        int subtract(int a, int b);
        void reset();
      };
    CPP
  end

  def create_header_with_static_method
    File.write(@test_header, <<~CPP)
      class Singleton {
      public:
        static Singleton* getInstance();
        void doSomething();
      };
    CPP
  end

  def create_header_with_const_method
    File.write(@test_header, <<~CPP)
      class Reader {
      public:
        int getValue() const;
        void setValue(int v);
      };
    CPP
  end

  def create_header_with_virtual_method
    File.write(@test_header, <<~CPP)
      class Drawable {
      public:
        virtual void draw();
        void update();
      };
    CPP
  end

  def create_header_with_inline_method
    File.write(@test_header, <<~CPP)
      class SimpleButton {
      public:
        bool wasClicked() const { return _clicked; }
      private:
        bool _clicked;
      };
    CPP
  end

  def create_header_with_multiple_inline_methods
    File.write(@test_header, <<~CPP)
      class Button {
      public:
        bool wasClicked() const { return _state == 1; }
        bool wasPressed() const { return !_oldPress && _press; }
        bool isHolding() const { return _press && _holdTime > 500; }
        void update() { _oldPress = _press; }
      private:
        int _state;
        bool _oldPress;
        bool _press;
        int _holdTime;
      };
    CPP
  end

  def create_header_with_preprocessor_directives
    File.write(@test_header, <<~CPP)
      class ConfigurableClass {
      public:
        // This pattern mimics M5Unified.hpp structure
        bool realMethod() {
      #ifdef SDL_h_
          SDL_Delay(100);
      #else
          delay(100);
      #endif
          return true;
        }
        void update();
      private:
        int _value;
      };
    CPP
  end

  def create_header_with_struct_member_parameter
    File.write(@test_header, <<~CPP)
      struct config_t {
        int atom_display;
        int module_display;
      };

      class Display {
      public:
        // This mimics M5Unified::dsp(const config_t& cfg) pattern
        int configure(const config_t& cfg) {
          return cfg.atom_display;  // Member access in body
        }
      };
    CPP
  end

  def create_header_with_unnamed_parameters
    File.write(@test_header, <<~CPP)
      class Processor {
      public:
        void process(int, float, bool);  // Unnamed parameters
      };
    CPP
  end
end
