function setup(wopr_sock) {
  wopr_sock.onopen = function (event) {
    console.log('onopen!')
    $('#title').css('background', '#0f0')
    wopr_sock.send("bigmac");
  };
  wopr_sock.onmessage = function (event) {
    console.log(event.data);
    $('#output').append('<div>'+event.data+'</div>')
  }
  wopr_sock.onclose = function (event) {
    $('#title').css('background', '#f00')
  }

}