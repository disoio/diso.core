(function() {
  var Client, Server;

  Client = require('./Client');

  Server = require('./Server');

  module.exports = {
    Server: Server,
    Client: Client
  };

}).call(this);
