(function() {
  var Cache, ClientStore, EventEmitter, Mediator, Message,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  Mediator = require('../Shared/Mediator');

  Message = require('../Shared/Message');

  Cache = require('../Shared/Cache');

  ClientStore = (function(_super) {
    __extends(ClientStore, _super);

    function ClientStore() {
      this._cache = new Cache();
      Mediator.on('message:invalidateCache', this._invalidateCache);
    }

    ClientStore.prototype._invalidateCache = function(message) {
      var cache_args, _i, _len, _ref, _results;
      _ref = message.data.remove;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cache_args = _ref[_i];
        _results.push(this._cache.remove(cache_args));
      }
      return _results;
    };

    ClientStore.prototype._key = function(args) {
      var key;
      if ('key' in args) {
        return args.key;
      } else {
        key = args.type;
        if ('id' in args) {
          key = "" + key + ":" + args.id;
        }
        return key;
      }
    };

    ClientStore.prototype._event = function(key) {
      return "update:" + key;
    };

    ClientStore.prototype.get = function(args) {
      var cache_args, callback, data, key, message;
      message = args.message;
      callback = args.callback;
      cache_args = args.cache;
      if (!Type(message, Message)) {
        message = new Message(message);
      }
      key = cache_args ? this._key(cache_args) : null;
      if (key) {
        data = this._cache.get({
          key: key
        });
        if (data) {
          return callback(null, data);
        }
      }
      return Mediator.send({
        message: message,
        callback: (function(_this) {
          return function(reply) {
            var event;
            if (reply.isError()) {
              return callback(reply.error, null);
            } else {
              data = reply.data;
              if (key) {
                _this._cache.put({
                  key: key,
                  data: data
                });
                event = _this._event(key);
                _this.emit(event, data);
              }
              return callback(null, data);
            }
          };
        })(this)
      });
    };

    ClientStore.prototype.subscribe = function(args) {
      var callback, event, key;
      callback = args.callback;
      key = this._key(args);
      event = this._event(key);
      return this.on(event, callback);
    };

    ClientStore.prototype.unsubscribe = function(args) {
      var callback, event, key;
      callback = args.callback;
      key = this._key(args);
      event = this._event(key);
      return this.removeListener(event, args.callback);
    };

    return ClientStore;

  })(EventEmitter);

  module.exports = ClientStore;

}).call(this);
