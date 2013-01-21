class Market
  attr_reader :offers

  def initialize(bidask)
    @offers = Hamster.list
    @bidask = bidask
  end

  def best_price
    head = offers.head
    if head
      head["price"]
    end
  end

  def size
    @offers.size
  end

  def value
    @offers.reduce(0){|total, offer| total + offer["price"]*offer["quantity"]}
  end

  def better_offer(price1, price2)
    if @bidask == 'ask'
      better = price1 <= price2
    elsif @bidask == 'bid'
      better = price1 >= price2
    end
  end

  def divide_offers_by(price)
    @offers.span{|o| better_offer(o["price"],price)}
  end

  # Mutators
  def sorted_insert(new_offer)
    better_offers, worse_offers = divide_offers_by(new_offer["price"])
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
      @offers = better_offers+worse_offers.cons(new_offer)
    end
    return better_offers.size
  end

  def remove_exchange(exchange)
    @offers.select{|o| o["exchange"] == exchange}.each{|o| @offers.delete(o)}
  end
end
