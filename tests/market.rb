require 'test/unit'
require 'wopr/market'

class MarketTest  < Test::Unit::TestCase
  def setup
    @bid_market = Market.new('bid')
  end

  def test_earliest_index
    # prereq: empty list
    assert_equal @bid_market.offers.size, 0
    @bid_market.sorted_insert({"price"=>10, "quantity"=>1})

    # first element
    position = @bid_market.earliest_index(10)
    assert_equal position, 0

    # before
    position = @bid_market.earliest_index(11)
    assert_equal position, 0

    # after
    position = @bid_market.earliest_index(9)
    assert_equal position, 1
  end

  def test_sorted_insert
    # prereq: empty list
    assert_equal @bid_market.offers.size, 0

    # First insert
    offer = {"price"=>10, "quantity"=>1}
    @bid_market.sorted_insert(offer)
    assert_equal 1, @bid_market.offers.size
    result = @bid_market.offers.first
    assert_equal offer["price"], result["price"]
    assert_equal offer["quantity"], result["quantity"]

    # Quantity update
    offer = {"price"=>10, "quantity"=>2}
    @bid_market.sorted_insert(offer)
    assert_equal 1, @bid_market.offers.size
    result = @bid_market.offers.first
    assert_equal offer["price"], result["price"]
    assert_equal offer["quantity"], result["quantity"]

    # Last insert
    offer = {"price"=>9, "quantity"=>1}
    @bid_market.sorted_insert(offer)
    assert_equal 2, @bid_market.offers.size
    result = @bid_market.offers.last
    assert_equal offer["price"], result["price"]
    assert_equal offer["quantity"], result["quantity"]

  end
end

