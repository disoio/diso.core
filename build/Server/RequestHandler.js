(function() {
  var FORMAT, RequestHandler, parseAcceptHeader,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  parseAcceptHeader = require('./parseAcceptHeader');

  FORMAT = {
    html: 'text/html',
    json: 'application/json',
    text: 'text/plain'
  };

  RequestHandler = (function() {
    function RequestHandler(args) {
      this._render = __bind(this._render, this);
      var messages;
      this._init_store = args.init_store;
      messages = args.messages;
      this._container = args.container;
    }

    RequestHandler.prototype.handle = function(request, response, next) {
      var page, _onError;
      _onError = function(error) {
        console.error(error);
        return next("500");
      };
      page = request.page;
      return this._container.load({
        page: page,
        callback: (function(_this) {
          return function(error) {
            if (error) {
              return _onError(error);
            }
            _this._init_store[page.key()] = _this._container.initData();
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

    return RequestHandler;

  })();

  module.exports = RequestHandler;

}).call(this);
