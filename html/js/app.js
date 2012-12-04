function setup(wopr_sock) {
  wopr_sock.onopen = function (event) {
    $('#title').css('background', '#0f0')
    wopr_sock.send("RELOAD");
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
      case "performance":
        console.log("[performance ]")
        show_performance(rpc.response)
        break;
    }
  }
  wopr_sock.onclose = function (event) {
    $('#title').css('background', '#f00')
  }
  wopr_sock.onerror = function (error) {
    console.log(error)
    $('#error').html(''+error.target.url+' failed')
  }
}

function show_performance(msg) {
  $('#perf').html(msg)
}

function show_offer(msg) {
  var display = msg["exchange"] +" "+ (msg["price"]) +" "+
                msg["quantity"]
  var bucket
  if(msg.bidask == "ask") {
    bucket = $('#asks')
  }
  if(msg.bidask == "bid") {
    bucket = $('#bids')
  }
  bucket.prepend("<div>"+display+"</div>")
}

function load_offers(msg) {
  var html = $('#bid-offer').html()
  var template = Handlebars.compile(html)

  msg["asks"].forEach(function(msg) {
    var bid = offer_tmpl_data(msg)
    $('#asks').prepend(template(bid))
  })

  msg["bids"].forEach(function(msg) {
    var bid = offer_tmpl_data(msg)
    $('#bids').prepend(template(bid))
  })
}

function offer_tmpl_data(msg) {
  var askbid = msg || {"price":"?","quantity":"?"}
  offer = {
    'price': askbid["price"],
    'quantity': askbid["quantity"],
    'exchange': askbid["exchange"]
  }
  return offer
}