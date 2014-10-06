(function() {
  var Cache, ClientModel, EventEmitter, Mediator, Message, _cache, _events;

  EventEmitter = require('events').EventEmitter;

  Mediator = require('../Shared/Mediator');

  Message = require('../Shared/Message');

  Cache = require('../Shared/Cache');

  _cache = new Cache();

  _events = new EventEmitter;

  ({
    _key: function(args) {
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
    },
    _event: function(key) {
      return "update:" + key;
    }
  });

  ClientModel = (function() {
    function ClientModel(data) {
      this.setData(data);
    }

    ClientModel.get = function(args) {
      var cache_args, callback, data, key, message;
      message = args.message;
      callback = args.callback;
      cache_args = args.cache;
      key = cache_args ? _key(cache_args) : null;
      if (key) {
        data = _cache.get({
          key: key
        });
        if (data) {
          return callback(null, data);
        }
      }
      if (!Type(message, Message)) {
        message = new Message(message);
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
                _cache.put({
                  key: key,
                  data: data
                });
                event = _this._event(key);
                _events.emit(event, data);
              }
              return callback(null, data);
            }
          };
        })(this)
      });
    };

    ClientModel.find = function(args) {
      var callback, _id;
      _id = args._id;
      callback = args.callback;
      return this.get({
        message: {
          name: 'find',
          data: {
            model: this.name,
            _id: _id
          }
        },
        callback: (function(_this) {
          return function(error, data) {
            if (error) {
              return callback(error, null);
            } else {
              return callback(null, data.model);
            }
          };
        })(this)
      });
    };

    ClientModel.subscribe = function(args) {
      var callback, event, key;
      callback = args.callback;
      key = _key(args);
      event = _event(key);
      return _events.on(event, callback);
    };

    ClientModel.unsubscribe = function(args) {
      var callback, event, key;
      callback = args.callback;
      key = _key(args);
      event = _event(key);
      return _events.removeListener(event, args.callback);
    };

    ClientModel.prototype.setData = function(data) {
      var k, v, _results;
      _results = [];
      for (k in data) {
        v = data[k];
        _results.push(this[k] = v);
      }
      return _results;
    };

    return ClientModel;

  })();

  module.exports = ClientModel;

}).call(this);
