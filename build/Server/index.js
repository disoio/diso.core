(function() {
  var Container, Mediator, RequestHandler, Server, SocketHandler;

  Server = require('./Server');

  RequestHandler = require('./RequestHandler');

  SocketHandler = require('./SocketHandler');

  Container = require('./ServerContainer');

  Mediator = require('../Shared/Mediator');

  Server.RequestHandler = RequestHandler;

  Server.SocketHandler = SocketHandler;

  Server.Container = Container;

  Server.Mediator = Mediator;

  module.exports = Server;

}).call(this);
