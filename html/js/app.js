function setup(wopr_sock) {
  var sweep_id;
  wopr_sock.onopen = function (event) {
    $('#title').css('background', '#0f0')
    wopr_sock.send("RELOAD");
    sweep_id = setInterval(time_sweep, 1000)
  };
  wopr_sock.onmessage = function (event) {
    rpc = JSON.parse(event.data)
    switch(rpc.type) {
      case "load":
        console.log("[load "+rpc.response.asks.length+" "+
                    rpc.response.bids.length+" ]")
        load_offers(rpc.response)
        break;
      case "offer":
        console.log("[offer ]")
        show_offer(rpc.response)
        break;
      case "size":
        console.log("[size ]")
        show_size(rpc.response)
        break;
      case "performance":
        console.log("[performance ]")
        show_performance(rpc.response)
        break;
    }
  }
  wopr_sock.onclose = function (event) {
    $('#title').css('background', '#f00')
    clearInterval(sweep_id)
  }
  wopr_sock.onerror = function (error) {
    console.log(error)
    $('#error').html(''+error.target.url+' failed')
    clearInterval(sweep_id)
  }
}

function time_sweep() {
  $('time').each(function(idx, el){
    old_time = new Date($(el).attr('datetime'))
    time_diff = (new Date()) - old_time
    $(el).html(time_diff)
  })
}

function show_performance(msg) {
  //build
  var html = $('#exchange-temp').html()
  var template = Handlebars.compile(html)
  msg.mps = msg.mps.toFixed(1)
  msg.duration = (new Date()) - (new Date(msg.time))

  // find
  var ex_el = $('#perf-'+msg.exchange)
  if(ex_el.length > 0) {
    // replace
    ex_el.html(template(msg))
  } else {
    // create
    $('#exchanges ul').append(template(msg))
  }
}

function show_size(msg) {
  var display = msg["size"]
  var bucket
  if(msg.bidask == "ask") {
    bucket = $('#total-asks')
  }
  if(msg.bidask == "bid") {
    bucket = $('#total-bids')
  }
  bucket.html("<div>"+display+"</div>")
}

function show_offer(msg) {
  var display = msg["exchange"] +" "+ (msg["price"]) +" "+
                msg["quantity"]
  var bucket = market_element(msg.bidask)
  bucket.prepend("<div>"+display+"</div>")
}

function load_offers(msg) {
  var html = $('#bid-offer').html()
  var template = Handlebars.compile(html)

  msg["asks"].forEach(function(msg) {
    var bid = offer_tmpl_data(msg)
    $('#asks .offers').prepend(template(bid))
  })
  $('#asks .total-usd').html(msg["total_asks_usd"].toFixed(2))
  $('#asks .total-btc').html(msg["total_asks_btc"].toFixed(2))

  msg["bids"].forEach(function(msg) {
    var bid = offer_tmpl_data(msg)
    $('#bids .offers').append(template(bid))
  })
  $('#bids .total-usd').html(msg["total_bids_usd"].toFixed(2))
  $('#bids .total-btc').html(msg["total_bids_btc"].toFixed(2))
  $('#profit').html(msg["profit"].toFixed(2))
}

function offer_tmpl_data(msg) {
  var askbid = msg || {"price":"?","quantity":"?"}
  offer = {
    'price': askbid["price"].toFixed(4),
    'quantity': askbid["quantity"].toFixed(3),
    'exchange': askbid["exchange"]
  }
  return offer
}

function market_element(market) {
  var bucket
  if(market == "ask") {
    bucket = $('#asks')
  }
  if(market == "bid") {
    bucket = $('#bids')
  }
  return bucket
}