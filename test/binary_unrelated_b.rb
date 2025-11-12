require_relative "test_helper"

class UnrelatedTestB < PraTestCase
  def test_b1
    assert_true(true)
  end
  
  def test_b2
    assert_false(false)
  end
end
