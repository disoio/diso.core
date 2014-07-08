(function() {
  var EventEmitter, Mediator, Type, cache,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  Type = require('type-of-is');

  cache = {};

  Mediator = (function(_super) {
    __extends(Mediator, _super);

    function Mediator() {
      return Mediator.__super__.constructor.apply(this, arguments);
    }

    Mediator.prototype.client = null;

    Mediator.prototype.setup = function(opts) {
      this.client = opts.client;
      this.models = opts.models;
      return this.router = opts.router;
    };

    Mediator.prototype.send = function(message) {
      return this.client.send(message);
    };

    Mediator.prototype.formatRoute = function(route) {
      return this.router.format(route);
    };

    Mediator.prototype.loadBody = function(options) {
      return this.client.loadBody(options);
    };

    Mediator.prototype.pushView = function(opts) {
      var url;
      this.client.page.swapBody(opts.view);
      url = this.formatRoute(opts.route);
      return this.client.navigate(url);
    };

    Mediator.prototype.cache = function(k, v) {
      if (v) {
        return cache[k] = v;
      } else if (k in cache) {
        return cache[k];
      } else {
        throw new Error("" + k + " not found in client cache");
      }
    };

    return Mediator;

  })(EventEmitter);

  module.exports = new Mediator();

}).call(this);
