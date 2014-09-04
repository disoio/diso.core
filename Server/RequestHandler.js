(function() {
  var FORMAT, RequestHandler, ServerStore, parseAcceptHeader,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  FORMAT = {
    html: 'text/html',
    json: 'application/json',
    text: 'text/plain'
  };

  parseAcceptHeader = require('./parseAcceptHeader');

  ServerStore = (function() {
    function ServerStore(args) {
      this.messages = args.messages;
    }

    ServerStore.prototype.get = function(args) {
      var callback, message;
      message = args.message;
      return callback = args.callback;
    };

    return ServerStore;

  })();

  RequestHandler = (function() {
    function RequestHandler(args) {
      this._render = __bind(this._render, this);
      var messages;
      this._init_store = args.init_store;
      messages = args.messages;
      this._container = args.container;
      this._store = new ServerStore({
        messages: messages
      });
    }

    RequestHandler.prototype._responseFormat = function(request) {
      var accept, accepts, k, parsed_accepts, type, types, v, _i, _len;
      accepts = request.headers['Accept'];
      if (accepts) {
        parsed_accepts = parseAcceptHeader(accepts);
        for (_i = 0, _len = parsed_accepts.length; _i < _len; _i++) {
          accept = parsed_accepts[_i];
          type = "" + accept.type + "/" + accept.subtype;
          types = (function() {
            var _results;
            _results = [];
            for (k in FORMAT) {
              v = FORMAT[k];
              _results.push(v);
            }
            return _results;
          })();
          if ((__indexOf.call(types, type) >= 0)) {
            return [k, type];
          }
        }
      }
      return ['html', FORMAT.html];
    };

    RequestHandler.prototype._render = function(args) {
      var body, content_type, format, headers, request, response, status, _ref;
      request = args.request;
      response = args.response;
      _ref = this._responseFormat(request), format = _ref[0], content_type = _ref[1];
      headers = this._container.headers();
      headers['Content-Type'] = content_type;
      status = this._container.status() || 200;
      body = this._container[format]();
      response.writeHead(status, headers);
      return response.end(body);
    };

    RequestHandler.prototype.run = function(args) {
      var next, request, response, _onError;
      request = args.request;
      response = args.response;
      next = args.next;
      _onError = function(error) {
        console.error(error);
        return next("500");
      };
      return this._container.load({
        page: request.page,
        store: this._store,
        callback: (function(_this) {
          return function(error) {
            if (error) {
              return _onError(error);
            }
            _this._init_store[_this._container.pageKey()] = _this._container.initData();
            try {
              return _this._render({
                request: request,
                response: response
              });
            } catch (_error) {
              error = _error;
              return _onError(error);
            }
          };
        })(this)
      });
    };

    return RequestHandler;

  })();

  module.exports = RequestHandler;

}).call(this);
