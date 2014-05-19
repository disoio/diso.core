(function() {
  var FORMAT, RequestHandler, Url, Utils,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Url = require('url');

  Utils = require('./Utils');

  FORMAT = {
    html: 'text/html',
    json: 'application/json',
    text: 'text/plain'
  };

  RequestHandler = (function() {
    function RequestHandler(options) {
      this.request = options.request;
      this.response = options.response;
      this.next = options.next;
      this.Actions = options.Actions;
      if ('Page' in this.Actions) {
        this.Page = this.Actions.Page;
      }
      this.parsed_url = Url.parse(this.request.url, true);
      this.actions = new this.Actions({
        session: this.request.session
      });
    }

    RequestHandler.prototype.params = function() {
      return this.request.route.params;
    };

    RequestHandler.prototype.method = function() {
      return this.request.method;
    };

    RequestHandler.prototype.actionName = function() {
      return this.request.route.name;
    };

    RequestHandler.prototype.Page = null;

    RequestHandler.prototype.path = function() {
      return this.parsed_url.pathname.slice(1);
    };

    RequestHandler.prototype.query = function() {
      return this.parsed_url.query;
    };

    RequestHandler.prototype.responseType = function() {
      var accept, accepts, k, type, types, v, _i, _len, _ref;
      accepts = this.request.headers['Accept'];
      if (accepts) {
        _ref = Utils.parseAcceptHeader(accepts);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          accept = _ref[_i];
          type = "" + accept.type + "/" + accept.subtype;
          for (k in FORMAT) {
            v = FORMAT[k];
            types = v;
          }
          if ((__indexOf.call(types, type) >= 0)) {
            return type;
          }
        }
      }
      return FORMAT.html;
    };

    RequestHandler.prototype.isXHR = function() {
      var req_with;
      req_with = this.request.headers['X-Requested-With'] || '';
      return req_with === 'xmlhttprequest';
    };

    RequestHandler.prototype.render = function(options) {
      var Page, View, body, data, format, headers, status, view;
      format = this.responseType();
      body = (function() {
        if (format === FORMAT.json) {
          return JSON.stringify(options.data);
        } else {
          if (!options.View) {
            throw "Action callback doesn't specify view";
          }
          View = options.View;
          data = options.data || {};
          Page = options.Page ? options.Page : this.Page ? this.Page : null;
          view = Page ? new Page({
            Body: View,
            route: this.actionName(),
            data: data,
            url: this.request.url
          }) : new View(data);
          this.request.session.initialization_data = {
            view_data: data,
            id_map: view.idMap()
          };
          if (format === FORMAT.text) {
            return view.text();
          } else {
            return view.html();
          }
        }
      }).call(this);
      headers = options.headers || {};
      headers['Content-Type'] = format;
      status = options.status || 200;
      this.response.writeHead(status, headers);
      return this.response.end(body);
    };

    RequestHandler.prototype.run = function() {
      var action, action_name, error;
      action_name = this.actionName();
      action = this.actions[action_name];
      if (action) {
        try {
          return action(this.params(), (function(_this) {
            return function(response) {
              if (response.error) {
                return _this.next(response.error);
              } else {
                return _this.render(response);
              }
            };
          })(this));
        } catch (_error) {
          error = _error;
          console.error(error);
          return this.next("Error");
        }
      } else {
        error = "Action:" + action_name + " is not supported";
        console.error(error);
        return this.next(error);
      }
    };

    return RequestHandler;

  })();

  module.exports = RequestHandler;

}).call(this);
