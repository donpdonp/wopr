class Market
  attr_reader :offers

  def initialize(bidask)
    @offers = Hamster.list
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

  def better_offer(price1, price2)
    if @bidask == 'ask'
      better = price1 <= price2
    elsif @bidask == 'bid'
      better = price1 >= price2
    end
  end

  # Mutators
  def sorted_insert(new_offer)
    better_offers, worse_offers = @offers.span{|o| better_offer(new_offer["price"],o["price"])}
    closest_or_same_offer = better_offers.last
    if closest_or_same_offer && closest_or_same_offer["price"] == new_offer["price"]
      same_offer = closest_or_same_offer
      if new_offer["quantity"] == 0
        # delete
        @offers = better_offers.take(better_offers.size-1) + worse_offers
      else
        # adjust volume
        same_offer["quantity"] = new_offer["quantity"]
      end
    else
      return if new_offer["quantity"] == 0 # bogus cancel
      @offers = better_offers.cons(new_offer)+worse_offers
    end
    return better_offers.size
  end

  def remove_exchange(exchange)
    @offers.select{|o| o["exchange"] == exchange}.each{|o| @offers.delete(o)}
  end
end
