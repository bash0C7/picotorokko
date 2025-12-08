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
end
