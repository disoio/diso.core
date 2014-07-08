(function() {
  var SocketHandler, Type, _sendMessage,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Type = require('type-of-is');

  _sendMessage = function(options) {
    var message, socket;
    socket = options.socket;
    message = options.message;
    if (!Type(message, String)) {
      message = JSON.stringify(message);
    }
    console.log("sending to socket=" + socket.id);
    console.log(message);
    return socket.send(message);
  };

  SocketHandler = (function() {
    SocketHandler.sockets = {};

    function SocketHandler(options) {
      this.sendMessage = __bind(this.sendMessage, this);
      this.sendReply = __bind(this.sendReply, this);
      this.sendError = __bind(this.sendError, this);
      this.onError = __bind(this.onError, this);
      this.onClose = __bind(this.onClose, this);
      this.onMessage = __bind(this.onMessage, this);
      var Actions, Messages;
      this.socket = options.socket;
      this.session = options.session;
      this.socket.session_id = this.session.id;
      this.actions = options.actions;
      Messages = options.Messages;
      this.messages = new Messages({
        handler: this
      });
      Actions = options.Actions;
      this.actions = new Actions({
        session: this.session
      });
      if (!(this.socket.id in this.constructor.sockets)) {
        this.constructor.sockets[this.socket.id] = this.socket;
      }
      this.socket.on('message', this.onMessage);
      this.socket.on('close', this.onClose);
      this.socket.on('error', this.onError);
      this.sendMessage({
        name: 'initialize',
        data: this.session.initialization_data
      });
      delete this.session.initialization_data;
    }

    SocketHandler.prototype.onMessage = function(raw_message) {
      var action, action_name, error, handler, message, params, stack;
      try {
        message = JSON.parse(raw_message);
      } catch (_error) {
        error = _error;
        console.error("Error parsing message: " + error);
        return this.sendMessage({
          error: "Message parse error"
        });
      }
      if (message.error) {
        console.error("Client error : " + message.error);
      } else {
        if (message.data == null) {
          message.data = {};
        }
      }
      switch (message.name) {
        case 'loadBody':
          params = message.data.route.params;
          action_name = message.data.route.name;
          action = this.actions[action_name];
          if (action) {
            try {
              return action(params, (function(_this) {
                return function(response) {
                  var data;
                  if (response != null ? response.error : void 0) {
                    return _this.sendError(response.error);
                  } else {
                    data = {
                      view_class_name: response.View.name,
                      view_data: response.data,
                      url: message.data.url
                    };
                    return _this.sendReply({
                      name: message.name,
                      data: data
                    });
                  }
                };
              })(this));
            } catch (_error) {
              error = _error;
              console.error(error);
              return this.sendError("Render error");
            }
          } else {
            error = "Action:" + action_name + " is not supported";
            console.error(error);
            return this.sendError(error);
          }
          break;
        default:
          handler = this.messages[message.name];
          console.log("Message received:\n" + (JSON.stringify(message, null, 2)));
          if (handler) {
            try {
              return handler(message.data, (function(_this) {
                return function(response) {
                  if (response != null ? response.error : void 0) {
                    return _this.sendError(response.error);
                  } else if (response) {
                    return _this.sendReply({
                      name: message.name,
                      data: response
                    });
                  }
                };
              })(this));
            } catch (_error) {
              error = _error;
              stack = new Error().stack;
              console.log(error);
              console.error(stack);
              return this.sendError('Error processing message');
            }
          } else {
            error = "Message:" + message.name + " is not supported";
            console.error(error);
            return this.sendError(error);
          }
      }
    };

    SocketHandler.prototype.onClose = function() {
      if (this.socket.id in this.constructor.sockets) {
        return delete this.constructor.sockets[this.socket.id];
      }
    };

    SocketHandler.prototype.onError = function(error) {
      console.error(error);
      return this.sendError("socket error");
    };

    SocketHandler.prototype.sendError = function(error) {
      return this.sendMessage({
        name: 'error',
        error: error
      });
    };

    SocketHandler.prototype.sendReply = function(message) {
      message.name = "" + message.name + "Reply";
      return this.sendMessage(message);
    };

    SocketHandler.prototype.sendMessage = function(message) {
      return _sendMessage({
        socket: this.socket,
        message: message
      });
    };

    SocketHandler.sendMessageAll = function(message) {
      var id, socket, _ref, _results;
      _ref = SocketHandler.sockets;
      _results = [];
      for (id in _ref) {
        socket = _ref[id];
        _results.push(_sendMessage({
          socket: socket,
          message: message
        }));
      }
      return _results;
    };

    return SocketHandler;

  })();

  module.exports = SocketHandler;

}).call(this);
