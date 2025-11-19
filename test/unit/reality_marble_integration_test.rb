require "test_helper"
require "reality_marble"

class RealityMarbleIntegrationTest < Test::Unit::TestCase
  # Reality Marble gem の基本機能を検証（新しいネイティブシンタックスAPI）
  sub_test_case "Reality Marble singleton method mocking" do
    test "mocks File.exist? method with define_singleton_method" do
      test_class = File

      marble = RealityMarble.chant do
        test_class.define_singleton_method(:exist?) do |_path|
          "/mock/path"
        end
      end

      # Before activate: should not be mocked
      original_result = test_class.exist?(__FILE__)

      # During activate: should be mocked
      marble.activate do
        assert_equal "/mock/path", test_class.exist?("/any/path")
      end

      # After activate: should be restored
      assert_equal original_result, test_class.exist?(__FILE__)
    end

    test "mocks multiple class methods" do
      test_class = Class.new

      marble = RealityMarble.chant do
        test_class.define_singleton_method(:add) do |a, b|
          a + b
        end

        test_class.define_singleton_method(:multiply) do |a, b|
          a * b
        end
      end

      result = marble.activate do
        assert_equal 15, test_class.add(10, 5)
        assert_equal 50, test_class.multiply(10, 5)
        { add: 15, multiply: 50 }
      end

      assert_equal({ add: 15, multiply: 50 }, result)
    end

    test "context automatically resets after activation" do
      test_class = Class.new

      marble = RealityMarble.chant do
        test_class.define_singleton_method(:value) { 42 }
      end

      marble.activate { assert_equal 42, test_class.value }

      # After activation, method should be removed
      assert_raises(NoMethodError) { test_class.value }
    end
  end

  # picotorokko テストでの実用例
  sub_test_case "Usage with Dir and file system mocking" do
    test "mocks Dir.glob for testing file discovery" do
      test_class = Dir

      marble = RealityMarble.chant do
        test_class.define_singleton_method(:glob) do |_pattern|
          ["/mock/dir1/file.txt", "/mock/dir2/file.txt"]
        end
      end

      marble.activate do
        result = Dir.glob("/mock/**/*.txt")
        assert_equal ["/mock/dir1/file.txt", "/mock/dir2/file.txt"], result
      end
    end

    test "captures state during mock execution" do
      call_count = { count: 0 }

      marble = RealityMarble.chant(capture: { counters: call_count }) do |cap|
        File.define_singleton_method(:read) do |_path|
          cap[:counters][:count] += 1
          "mocked content"
        end
      end

      marble.activate do
        File.read("/any/path")
        File.read("/another/path")
        assert_equal 2, call_count[:count]
      end

      # Counter should remain at 2 after activation
      assert_equal 2, call_count[:count]
    end
  end

  teardown do
    # Context cleanup
    RealityMarble::Context.reset_current
  end
end
