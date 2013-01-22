require 'test/unit'
require 'wopr/market'

class MarketTest  < Test::Unit::TestCase
  def setup
    @bid_market = Market.new('bid')
  end

  def test_earliest_index
    # prereq: one element list [10]
    @bid_market.sorted_insert({"price"=>10, "quantity"=>1})
    assert_equal 1, @bid_market.offers.size

    # same rank
    position = @bid_market.earliest_index(10)
    assert_equal 0, position

    # better rank
    position = @bid_market.earliest_index(11)
    assert_equal 0, position

    # worse rank
    position = @bid_market.earliest_index(9)
    assert_equal 1, position

    # prereq: two element list [10, 9]
    @bid_market.sorted_insert({"price"=>9, "quantity"=>1})
    assert_equal @bid_market.offers.size, 2

    # same rank
    position = @bid_market.earliest_index(9)
    assert_equal 1, position

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

    # Middle insert
    offer = {"price"=>9.5, "quantity"=>1}
    @bid_market.sorted_insert(offer)
    assert_equal 3, @bid_market.offers.size

    # 0 volume is cancel
    offer = {"price"=>9, "quantity"=>0}
    @bid_market.sorted_insert(offer)
    assert_equal 2, @bid_market.offers.size
  end
end

