require 'test/unit'
require 'wopr/market'

class MarketTest  < Test::Unit::TestCase
  def setup
    @bid_market = Market.new('bid')
  end

  def test_sorted_insert
    # prereq: empty list
    assert_equal @bid_market.offers.size, 0

    # first element
    offer = {"price"=>10}
    position = @bid_market.sorted_insert(offer)
    assert_equal position, 0

    # before
    offer = {"price"=>11}
    position = @bid_market.sorted_insert(offer)
    assert_equal position, 0

    # after
    offer = {"price"=>9}
    position = @bid_market.sorted_insert(offer)
    assert_equal position, 2
  end
end

