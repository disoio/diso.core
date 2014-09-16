(function() {
  var ServerStore;

  ServerStore = (function() {
    function ServerStore(_messages) {
      this._messages = _messages;
    }

    ServerStore.prototype.get = function(args) {
      var callback, error, handler, message;
      message = args.message;
      callback = args.callback;
      handler = this._messages[message.name];
      if (handler) {
        return handler({
          message: message,
          callback: callback
        });
      } else {
        error = new Error("Message:" + message.name + " is not supported");
        console.error(error);
        return callback(error);
      }
    };

    return ServerStore;

  })();

  module.exports = ServerStore;

}).call(this);
