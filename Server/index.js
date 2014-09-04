(function() {
  var Container, Mediator, RequestHandler, Server, SocketHandler, Store;

  Server = require('./Server');

  RequestHandler = require('./RequestHandler');

  SocketHandler = require('./SocketHandler');

  Container = require('./ServerContainer');

  Store = require('./ServerStore');

  Mediator = require('../Shared/Mediator');

  Server.RequestHandler = RequestHandler;

  Server.SocketHandler = SocketHandler;

  Server.Container = Container;

  Server.Store = Store;

  Server.Mediator = Mediator;

  module.exports = Server;

}).call(this);
