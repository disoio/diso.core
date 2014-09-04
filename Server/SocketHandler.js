(function() {
  var JWT, Message, SocketHandler, TOKEN, Type,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Type = require('type-of-is');

  JWT = require('jwt-simple');

  Message = require('../Shared/Message');

  TOKEN = {
    EXPIRES: 'exp',
    ISSUER: 'iss'
  };

  SocketHandler = (function() {
    SocketHandler._sockets = {};

    function SocketHandler(args) {
      this._sendMessageAll = __bind(this._sendMessageAll, this);
      this._sendMessage = __bind(this._sendMessage, this);
      this._sendError = __bind(this._sendError, this);
      this._onError = __bind(this._onError, this);
      this._onClose = __bind(this._onClose, this);
      this._addUserIdFromToken = __bind(this._addUserIdFromToken, this);
      this._onMessage = __bind(this._onMessage, this);
      this._socket = args.socket;
      this._jwt_secret = args.jwt_secret;
      this._messages = args.messages;
      this._init_store = args.init_store;
      this.constructor._sockets[this._socket.id] = this._socket;
      this._socket.on('message', this._onMessage);
      this._socket.on('close', this._onClose);
      this._socket.on('error', this._onError);
    }

    SocketHandler.prototype._onMessage = function(raw_message) {
      var error, handler, message;
      console.log("RCV " + raw_message);
      message = Message.parse(raw_message);
      if (message.isError()) {
        console.error("Client error: " + message.error);
        return;
      }
      this._addUserIdFromToken(message);
      if (message["in"](['initialize', 'authenticate'])) {
        return this["_" + message.name](message);
      } else {
        handler = this._messages[message.name];
        if (handler) {
          return handler({
            message: message,
            callback: (function(_this) {
              return function(response) {
                var reply;
                if (response != null ? response.error : void 0) {
                  return _this._sendError(response.error);
                } else if (response) {
                  reply = message.reply(response);
                  return _this._sendMessage(reply);
                }
              };
            })(this)
          });
        } else {
          error = "Message:" + message.name + " is not supported";
          console.error(error);
          return this._sendError(error);
        }
      }
    };

    SocketHandler.prototype._initialize = function(message) {
      var init_data, page_key, reply;
      page_key = message.data.page_key;
      init_data = this._init_store[page_key];
      reply = message.reply(init_data);
      return this._sendMessage(reply);
    };

    SocketHandler.prototype._authenticate = function(message) {
      return this._messages.authenticate({
        message: message,
        callback: (function(_this) {
          return function(response) {
            var body, expires, reply, token, user;
            if (response.error) {
              return _this._sendError(response.error);
            }
            user = response.user;
            body = {};
            body[TOKEN.ISSUER] = user.id();
            expires = Type(user.tokenExpires, Function) ? user.tokenExpires() : null;
            if (expires) {
              body[TOKEN.EXPIRES] = expires;
            }
            token = JWT.encode(body, _this._jwt_secret);
            reply = message.reply({
              token: token,
              expires: expires,
              user: user
            });
            _this._sendMessage(reply);
            if (Type(user.saveToken, Function)) {
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

    SocketHandler.prototype._addUserIdFromToken = function(message) {
      var body, expired, expires, now;
      if (message.token) {
        body = JWT.decode(message.token, this._jwt_secret);
        expires = body[TOKEN.EXPIRES];
        expired = expires ? (now = Date.now(), expires < now) : false;
        if (!expired) {
          return message.user_id = body[TOKEN.ISSUER];
        }
      }
    };

    SocketHandler.prototype._onClose = function() {
      return delete this.constructor._sockets[this._socket.id];
    };

    SocketHandler.prototype._onError = function(error) {
      return console.error(error);
    };

    SocketHandler.prototype._sendError = function(error) {
      var message;
      message = Message.error(error);
      return this._sendMessage(message);
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
