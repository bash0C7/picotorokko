# frozen_string_literal: true

require_relative "test_helper"

# Test M5LibGen version constant
class VersionTest < Test::Unit::TestCase
  def test_version_defined
    assert_not_nil M5LibGen::VERSION
  end

  def test_version_format
    assert_match(/\A\d+\.\d+\.\d+\z/, M5LibGen::VERSION)
  end
end
