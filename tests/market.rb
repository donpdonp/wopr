require 'test/unit'
require 'wopr'

class MarketTest  < Test::Unit::TestCase
  def setup
    @bid_market = Market.new('bid')
  end

  def test_better_offer
    assert_equal true, @bid_market.better_offer(8,3)
    assert_equal true, @bid_market.better_offer(3,3)
    assert_equal false, @bid_market.better_offer(4,5)
  end

  def test_divide_offers_by_empty
    better,worse = @bid_market.divide_offers_by(5)
    assert_equal 0, better.size
    assert_equal 0, worse.size
  end

  def test_divide_offers_by_high_price
    #setup
    offer = {"price"=>10, "quantity"=>1}
    @bid_market.sorted_insert(offer)
    assert_equal 1, @bid_market.offers.size

    better,worse = @bid_market.divide_offers_by(5)
    assert_equal 1, better.size
    assert_equal 0, worse.size
  end

  def test_divide_offers_by_high_and_low_price
    #setup
    offer = {"price"=>10, "quantity"=>1}
    @bid_market.sorted_insert(offer)
    offer = {"price"=>1, "quantity"=>1}
    @bid_market.sorted_insert(offer)
    assert_equal 2, @bid_market.offers.size

    better,worse = @bid_market.divide_offers_by(5)
    assert_equal 1, better.size, "market: #{@bid_market.offers.inspect} better: #{better.size} worse: #{worse.size}"
    assert_equal 1, worse.size
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
    assert_equal 1, @bid_market.offers.size, @bid_market.offers.inspect
    result = @bid_market.offers.first
    assert_equal offer["price"], result["price"]
    assert_equal offer["quantity"], result["quantity"]

    # Last insert
    offer = {"price"=>9, "quantity"=>1}
    @bid_market.sorted_insert(offer)
    assert_equal 2, @bid_market.offers.size
    result = @bid_market.offers.last
    assert_equal offer["price"], result["price"], @bid_market.offers.inspect
    assert_equal offer["quantity"], result["quantity"]

    # 0 volume is cancel
    offer = {"price"=>9, "quantity"=>0}
    @bid_market.sorted_insert(offer)
    assert_equal 1, @bid_market.offers.size
  end
end

