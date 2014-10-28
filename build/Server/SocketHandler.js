(function() {
  var Message, SocketHandler, Type,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Type = require('type-of-is');

  Message = require('../Shared/Message');

  SocketHandler = (function() {
    SocketHandler._sockets = {};

    function SocketHandler(args) {
      this._sendMessageAll = __bind(this._sendMessageAll, this);
      this._sendMessage = __bind(this._sendMessage, this);
      this._onMessage_unsubscribe = __bind(this._onMessage_unsubscribe, this);
      this._onMessage_subscribe = __bind(this._onMessage_subscribe, this);
      this._onError = __bind(this._onError, this);
      this._onClose = __bind(this._onClose, this);
      this._onMessage = __bind(this._onMessage, this);
      this._socket = args.socket;
      this._models = args.models;
      this._messages = args.messages;
      this._init_store = args.init_store;
      this._jwt = args.jwt;
      this.constructor._sockets[this._socket.id] = this._socket;
      this._socket.on('message', this._onMessage);
      this._socket.on('close', this._onClose);
      this._socket.on('error', this._onError);
    }

    SocketHandler.prototype._onMessage = function(raw_message) {
      var message, _doReply;
      console.log("RCV " + raw_message);
      message = Message.parse(raw_message);
      if (message.isError()) {
        console.error("Client error: " + message.error);
        return;
      }
      _doReply = (function(_this) {
        return function(reply_data) {
          var reply;
          reply = message.reply(reply_data);
          return _this._sendMessage(reply);
        };
      })(this);
      return this._jwt.handleMessage({
        message: message,
        callback: (function(_this) {
          return function(error) {
            var handler, internal_messages;
            if (error) {
              console.error(error);
              return _doReply({
                error: "Error processing token"
              });
            } else {
              internal_messages = ['initialize', 'authenticate', 'find', 'subscribe', 'unsubscribe'];
              if (message["in"](internal_messages)) {
                return _this["_onMessage_" + message.name](message);
              } else {
                handler = _this._messages[message.name];
                if (handler) {
                  return handler({
                    message: message,
                    callback: function(error, data) {
                      return _doReply({
                        error: error,
                        data: data
                      });
                    }
                  });
                } else {
                  error = "Message:" + message.name + " is not supported";
                  console.error(error);
                  return _doReply({
                    error: error
                  });
                }
              }
            }
          };
        })(this)
      });
    };

    SocketHandler.prototype._onClose = function() {
      return delete this.constructor._sockets[this._socket.id];
    };

    SocketHandler.prototype._onError = function(error) {
      return console.error(error);
    };

    SocketHandler.prototype._onMessage_initialize = function(message) {
      var init_data, page_key, reply;
      page_key = message.data.page_key;
      init_data = this._init_store[page_key];
      reply = message.reply({
        data: init_data
      });
      return this._sendMessage(reply);
    };

    SocketHandler.prototype._onMessage_authenticate = function(message) {
      return this._messages.authenticate({
        message: message,
        callback: (function(_this) {
          return function(error, user) {
            var jwt_data, reply;
            jwt_data = error ? null : _this._jwt.encode(user);
            reply = message.reply({
              error: error,
              data: jwt_data
            });
            _this._sendMessage(reply);
            if (!error && Type(user.saveToken, Function)) {
              return user.saveToken({
                token: jwt_data.token,
                callback: function(error) {
                  if (error) {
                    return console.error(error);
                  }
                }
              });
            }
          };
        })(this)
      });
    };

    SocketHandler.prototype._onMessage_find = function(message) {
      var Model, data, error, model_name, _error, _id, _reply;
      data = message.data;
      _id = data._id;
      model_name = data.model;
      _reply = (function(_this) {
        return function(reply_data) {
          var reply;
          reply = message.reply(reply_data);
          return _this._sendMessage(reply);
        };
      })(this);
      _error = (function(_this) {
        return function(error) {
          console.error(error);
          return _reply({
            data: null,
            error: new Error("Model not found")
          });
        };
      })(this);
      Model = this._models[model_name];
      if (!Model) {
        error = new Error("Could not find model named '" + model_name + "'");
        return _error(error);
      }
      return Model.find({
        _id: _id,
        callback: function(error, model) {
          if (error) {
            return _error(error);
          }
          if (model) {
            return _reply({
              error: null,
              data: {
                model: model
              }
            });
          } else {
            error = new Error("Could not find " + model_name + " with id " + _id);
            return _error(error);
          }
        }
      });
    };

    SocketHandler.prototype._onMessage_subscribe = function(message) {
      var data, topic;
      data = message.data;
      return topic = data.topic;
    };

    SocketHandler.prototype._onMessage_unsubscribe = function(message) {
      var data, topic;
      data = message.data;
      return topic = data.topic;
    };

    SocketHandler.prototype._sendMessage = function(message) {
      var raw_message;
      raw_message = message.stringify();
      console.log("SND " + raw_message);
      return this._socket.send(raw_message);
    };

    SocketHandler.prototype._sendMessageAll = function(message) {
      var id, raw_message, socket, _ref, _results;
      _ref = this.constructor._sockets;
      _results = [];
      for (id in _ref) {
        socket = _ref[id];
        raw_message = message.stringify();
        _results.push(socket.send(raw_message));
      }
      return _results;
    };

    return SocketHandler;

  })();

  module.exports = SocketHandler;

}).call(this);
