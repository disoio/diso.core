(function() {
  var Cache, ClientStore, EventEmitter, Mediator, Message,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  Mediator = require('../Shared/Mediator');

  Message = require('../Shared/Message');

  Cache = (function() {
    function Cache(_store) {
      this._store = _store;
    }

    Cache.prototype._data = {};

    Cache.prototype._key = function(args) {
      return "" + args.type + ":" + args.id;
    };

    Cache.prototype.get = function(args) {
      var key;
      key = this._key(args);
      if (key in this._data) {
        return this._data[key];
      } else {
        return null;
      }
    };

    Cache.prototype.put = function(args) {
      var data, key;
      key = this._key(args);
      data = args.data;
      this._data[key] = data;
      return this._store.emit(key, data);
    };

    Cache.prototype.remove = function(args) {
      var key;
      key = this._key(args);
      return delete this._data[key];
    };

    return Cache;

  })();

  ClientStore = (function(_super) {
    __extends(ClientStore, _super);

    function ClientStore(args) {
      this._cache = new Cache(this);
      Mediator.on('message:cache:invalidate', this._invalidateCache);
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

    ClientStore.prototype.get = function(args) {
      var cache_args, callback, data, message, reply_evt;
      message = args.message;
      callback = args.callback;
      cache_args = args.cache;
      if (!Type(message, Message)) {
        message = new Message(message);
      }
      if (cache_args) {
        data = this._cache.get(cache_args);
        if (data) {
          return callback(null, data);
        }
      }
      Mediator.send(message);
      reply_evt = message.replyEventName();
      return Mediator.once(reply_evt, (function(_this) {
        return function(message) {
          if (message.error) {
            return callback(message.error);
          } else {
            data = message.data;
            if (cache_args) {
              cache_args.data = data;
              _this._cache.put(cache_args);
            }
            return callback(null, data);
          }
        };
      })(this));
    };

    ClientStore.prototype.subscribe = function(args) {
      var key;
      key = this._key(args);
      return this.on(key, args.callback);
    };

    ClientStore.prototype.unsubscribe = function(args) {
      var key;
      key = this._key(args);
      return this.removeListener(key, args.callback);
    };

    return ClientStore;

  })(EventEmitter);

  module.exports = ClientStore;

}).call(this);
