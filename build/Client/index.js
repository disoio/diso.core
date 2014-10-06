(function() {
  var Client, Container, Mediator, Model;

  Client = require('./Client');

  Model = require('./ClientModel');

  Container = require('./ClientContainer');

  Mediator = require('../Shared/Mediator');

  Client.Model = Model;

  Client.Container = Container;

  Client.Mediator = Mediator;

  module.exports = Client;

}).call(this);
