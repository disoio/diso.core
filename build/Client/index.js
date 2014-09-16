(function() {
  var Client, Container, Mediator, Model, Store;

  Client = require('./Client');

  Model = require('./ClientModel');

  Store = require('./ClientStore');

  Container = require('./ClientContainer');

  Mediator = require('../Shared/Mediator');

  Client.Model = Model;

  Client.Store = Store;

  Client.Container = Container;

  Client.Mediator = Mediator;

  module.exports = Client;

}).call(this);
