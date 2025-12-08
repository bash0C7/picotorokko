# frozen_string_literal: true

require_relative "test_helper"

# Test M5LibGen module loading and structure
class M5LibGenTest < Test::Unit::TestCase
  def test_require_works
    assert_nothing_raised do
      require "m5libgen"
    end
  end

  def test_module_defined
    assert defined?(M5LibGen), "M5LibGen module should be defined"
  end
end
