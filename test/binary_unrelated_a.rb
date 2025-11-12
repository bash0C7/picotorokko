require_relative "test_helper"

class UnrelatedTestA < PraTestCase
  def test_a1
    assert_equal(1, 1)
  end
  
  def test_a2
    assert_equal(2, 2)
  end
end
