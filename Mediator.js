(function() {
  var EventEmitter, Mediator,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  Mediator = (function(_super) {
    __extends(Mediator, _super);

    function Mediator() {
      return Mediator.__super__.constructor.apply(this, arguments);
    }

    Mediator.prototype.client = null;

    Mediator.prototype.ensureClient = function() {
      if (!this.client) {
        throw "Mediator has no client";
      }
    };

    Mediator.prototype.ensureRouter = function() {
      if (!this.router) {
        throw "Mediator has no router";
      }
    };

    Mediator.prototype.send = function(message) {
      this.ensureClient();
      return this.client.send(message);
    };

    Mediator.prototype.formatRoute = function(options) {
      this.ensureRouter();
      return this.router.format(options);
    };

    Mediator.prototype.swapBody = function(options) {
      this.ensureClient();
      return this.client.swapBody(options);
    };

    return Mediator;

  })(EventEmitter);

  module.exports = new Mediator();

}).call(this);
