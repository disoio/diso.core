(function() {
  var Container, Mediator, RequestHandler, Server, ServerModel, SocketHandler;

  Server = require('./Server');

  RequestHandler = require('./RequestHandler');

  SocketHandler = require('./SocketHandler');

  Container = require('./ServerContainer');

  ServerModel = require('./ServerModel');

  Mediator = require('../Shared/Mediator');

  Server.RequestHandler = RequestHandler;

  Server.SocketHandler = SocketHandler;

  Server.Container = Container;

  Server.Model = ServerModel;

  Server.Mediator = Mediator;

  module.exports = Server;

}).call(this);
