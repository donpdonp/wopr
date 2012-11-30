class Market
  attr_reader :offers

  def initialize(bidask)
    @offers = []
    @bidask = bidask
  end

  def sorted_insert(new_offer)
    offer_rank = earliest_index(new_offer["price"])
    if offer_rank < @offers.size
      matching_offer = @offers[offer_rank]
      if new_offer["price"] == matching_offer["price"]
        #adjust volume
        if new_offer["quantity"] == 0
          @offers.delete(offer_rank)
        else
          matching_offer["quantity"] = new_offer["quantity"]
        end
        return
      end
    end
    @offers.insert(offer_rank, new_offer)
    offer_rank
  end

  def earliest_index(price)
    highest = nil
    size = @offers.size
    @offers.each_with_index do |offer, idx|
      last = idx+1 == size
      highest = idx
      if @bidask == 'ask'
        better = price <= offer["price"]
      elsif @bidask == 'bid'
        better = price >= offer["price"]
      end
      break if better
      highest = size if last
    end
    highest || 0
  end
end