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
    @bid_market.sorted_insert(offer)
    assert_equal @bid_market.offers.first["price"], offer["price"]

    # before
    offer = {"price"=>11}
    @bid_market.sorted_insert(offer)
    assert_equal @bid_market.offers.first["price"], offer["price"]

    # after
    offer = {"price"=>9}
    @bid_market.sorted_insert(offer)
    assert_equal @bid_market.offers.last["price"], offer["price"]
  end
end

