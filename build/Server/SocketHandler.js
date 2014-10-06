(function() {
  var JWT, Message, SocketHandler, TOKEN, Type,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Type = require('type-of-is');

  JWT = require('jwt-simple');

  Message = require('../Shared/Message');

  TOKEN = {
    Expires: 'exp',
    Issuer: 'iss'
  };

  SocketHandler = (function() {
    SocketHandler._sockets = {};

    function SocketHandler(args) {
      this._sendMessageAll = __bind(this._sendMessageAll, this);
      this._sendMessage = __bind(this._sendMessage, this);
      this._addUserIdFromToken = __bind(this._addUserIdFromToken, this);
      this._onError = __bind(this._onError, this);
      this._onClose = __bind(this._onClose, this);
      this._onMessage = __bind(this._onMessage, this);
      this._socket = args.socket;
      this._models = args.models;
      this._jwt_secret = args.jwt_secret;
      this._messages = args.messages;
      this._init_store = args.init_store;
      this.constructor._sockets[this._socket.id] = this._socket;
      this._socket.on('message', this._onMessage);
      this._socket.on('close', this._onClose);
      this._socket.on('error', this._onError);
    }

    SocketHandler.prototype._onMessage = function(raw_message) {
      var error, handler, message, reply;
      console.log("RCV " + raw_message);
      message = Message.parse(raw_message);
      if (message.isError()) {
        console.error("Client error: " + message.error);
        return;
      }
      this._addUserIdFromToken(message);
      if (message["in"](['initialize', 'authenticate', 'find'])) {
        return this["_" + message.name](message);
      } else {
        handler = this._messages[message.name];
        if (handler) {
          return handler({
            message: message,
            callback: (function(_this) {
              return function(error, data) {
                var reply;
                reply = message.reply({
                  error: error,
                  data: data
                });
                return _this._sendMessage(reply);
              };
            })(this)
          });
        } else {
          error = "Message:" + message.name + " is not supported";
          console.error(error);
          reply = message.reply({
            error: error
          });
          return this._sendMessage(reply);
        }
      }
    };

    SocketHandler.prototype._onClose = function() {
      return delete this.constructor._sockets[this._socket.id];
    };

    SocketHandler.prototype._onError = function(error) {
      return console.error(error);
    };

    SocketHandler.prototype._initialize = function(message) {
      var init_data, page_key, reply;
      page_key = message.data.page_key;
      init_data = this._init_store[page_key];
      reply = message.reply({
        data: init_data
      });
      return this._sendMessage(reply);
    };

    SocketHandler.prototype._authenticate = function(message) {
      return this._messages.authenticate({
        message: message,
        callback: (function(_this) {
          return function(error, user) {
            var body, data, expires, reply, token;
            if (!error) {
              body = {};
              body[TOKEN.Issuer] = user.id();
              expires = Type(user.tokenExpires, Function) ? user.tokenExpires() : null;
              if (expires) {
                body[TOKEN.Expires] = expires;
              }
              token = JWT.encode(body, _this._jwt_secret);
              data = {
                token: token,
                expires: expires,
                user: user
              };
            }
            reply = message.reply({
              error: error,
              data: data
            });
            _this._sendMessage(reply);
            if (!error && Type(user.saveToken, Function)) {
              return user.saveToken({
                token: token,
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

    SocketHandler.prototype._find = function(message) {
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

    SocketHandler.prototype._addUserIdFromToken = function(message) {
      var body, expired, expires, now;
      if (message.token) {
        body = JWT.decode(message.token, this._jwt_secret);
        expires = body[TOKEN.Expires];
        expired = expires ? (now = Date.now(), expires < now) : false;
        if (!expired) {
          return message.user_id = body[TOKEN.Issuer];
        }
      }
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
