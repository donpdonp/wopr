class Market
  attr_reader :offers

  def initialize(bidask)
    @offers = []
    @bidask = bidask
  end

  def better_than(price)
    if offers.size > 0 && price
      range = 0..earliest_index(price)
      offers[range]
    else
      []
    end
  end

  def best_price
    if offers.size > 0
      offers[0]["price"]
    end
  end

  def size
    @offers.reduce(0){|total, offer| total + offer["price"]*offer["quantity"]}
  end

  def sorted_insert(new_offer)
    offer_rank = earliest_index(new_offer["price"])
    if offer_rank < @offers.size
      existing_offer = @offers[offer_rank]
      if new_offer["price"] == existing_offer["price"]
        #adjust volume
        if new_offer["quantity"] == 0
          @offers.delete_at(offer_rank)
        else
          existing_offer["quantity"] = new_offer["quantity"]
        end
        return offer_rank
      end
    end
    return offer_rank if new_offer["quantity"] == 0 # wayward cancel
    @offers.insert(offer_rank, new_offer)
    offer_rank
  end

  def better_offer(price1, price2)
    if @bidask == 'ask'
      better = price1 < price2
    elsif @bidask == 'bid'
      better = price1 > price2
    end
  end

  def earliest_index(price)
    highest = 0
    # empty check
    return highest if @offers.empty?
    # worst check
    return @offers.size if better_offer(@offers.last["price"], price)

    @offers.each_with_index do |offer, idx|
      highest = idx
      break if better_offer(price, offer["price"])
    end
    highest
  end

  def remove_exchange(exchange)
    @offers = @offers.reject{|o| o["exchange"] == exchange}
  end
end
