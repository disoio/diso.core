(function() {
  var EventEmitter, Mediator, Type, mediator,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  Type = require('type-of-is');

  Mediator = (function(_super) {
    __extends(Mediator, _super);

    function Mediator() {
      return Mediator.__super__.constructor.apply(this, arguments);
    }

    Mediator.prototype.delegate = function(map) {
      var method, target, _results;
      _results = [];
      for (method in map) {
        target = map[method];
        _results.push((function(_this) {
          return function(method, target) {
            return _this[method] = function() {
              return target[method].apply(target, arguments);
            };
          };
        })(this)(method, target));
      }
      return _results;
    };

    return Mediator;

  })(EventEmitter);

  mediator = new Mediator();

  mediator.setMaxListeners(50);

  module.exports = mediator;

}).call(this);
