function setup(wopr_sock) {
  wopr_sock.onopen = function (event) {
    $('#title').css('background', '#0f0')
    wopr_sock.send("RELOAD");
  };
  wopr_sock.onmessage = function (event) {
    console.log(event.data);
    msg = JSON.parse(event.data)
    if(msg.mps) {
      $('#perf').html(event.data)
    } else {
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
  }
  wopr_sock.onclose = function (event) {
    $('#title').css('background', '#f00')
  }
  wopr_sock.onerror = function (error) {
    console.log(error)
    $('#error').html(''+error.target.url+' failed')
  }
}