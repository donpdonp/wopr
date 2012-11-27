
var express = require('express');
var app = express();
app.configure(function(){
  app.use(express.static(__dirname + '/../html'));
});

console.log('web server listening on 3001')
app.listen(3001);