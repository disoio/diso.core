(function() {
  var $, Client, EngineIO, Mediator, Router, has_run,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $ = require('jquery');

  EngineIO = require('engine.io-client');

  Router = require('diso.router');

  Mediator = require('./Mediator');

  has_run = false;

  Client = (function() {
    Client.run = function(options) {
      var client;
      if (!has_run) {
        client = new Client(options);
        client.run();
        return has_run = true;
      }
    };

    function Client(options) {
      this.send = __bind(this.send, this);
      this.onClose = __bind(this.onClose, this);
      this.onMessage = __bind(this.onMessage, this);
      this.onOpen = __bind(this.onOpen, this);
      this.run = __bind(this.run, this);
      this.onPopState = __bind(this.onPopState, this);
      var Messages, routes, socket_url;
      this.Views = options.Views;
      routes = options.routes;
      Messages = options.Messages;
      this.messages = new Messages({
        client: this
      });
      this.router = new Router();
      this.router.route(routes);
      Mediator.client = this;
      Mediator.router = this.router;
      Mediator.on('error', (function(_this) {
        return function(message) {
          return _this.onError(message.error);
        };
      })(this));
      socket_url = "ws://" + window.location.host;
      this.socket = new EngineIO(socket_url);
      this.socket.onopen = this.onOpen;
      this.socket.onmessage = this.onMessage;
      this.socket.onclose = this.onClose;
      this.dom_ready = false;
      this.has_run = false;
      this.initial_data = null;
      $(document).ready((function(_this) {
        return function() {
          _this.dom_ready = true;
          return _this.run();
        };
      })(this));
    }

    Client.prototype.setupHistory = function() {
      if (this.supportsHistory()) {
        return $(window).on('popstate', this.onPopState);
      }
    };

    Client.prototype.supportsHistory = function() {
      return !!(window.history && window.history.pushState);
    };

    Client.prototype.navigate = function(url) {
      if (this.supportsHistory()) {
        return window.history.pushState(null, null, url);
      } else {
        return window.location = url;
      }
    };

    Client.prototype.onPopState = function() {
      return this.swapBody({
        url: document.location
      });
    };

    Client.prototype.swapBody = function(options) {
      if ('url' in options) {
        options.route = this.router.match({
          url: options.url
        });
      } else if ('route' in options) {
        options.url = this.router.format(options.route);
      } else {
        throw "Must pass url or params to swap body";
      }
      return this.send({
        name: 'swapBody',
        data: options
      });
    };

    Client.prototype.run = function() {
      var Body, Page, body, body_view_class_name, page_view_class_name;
      if (this.has_run) {
        return;
      }
      if (this.dom_ready && this.initial_data) {
        this.setupHistory();
        body = $('body');
        page_view_class_name = body.attr('data-page-type');
        body_view_class_name = body.attr('data-body-type');
        this.page = null;
        if ((page_view_class_name in this.Views) && (body_view_class_name in this.Views)) {
          Page = this.Views[page_view_class_name];
          Body = this.Views[body_view_class_name];
          this.page = Page.create({
            Body: Body,
            data: this.initial_data.view_data,
            id_map: this.initial_data.id_map,
            url: document.location
          });
          this.initial_data = null;
          if ('clientReady' in this.messages) {
            this.messages.clientReady();
          }
        }
        return this.has_run = true;
      }
    };

    Client.prototype.onOpen = function() {};

    Client.prototype.onMessage = function(raw_message) {
      var View, error, handler, message, url, view, view_class_name, view_data;
      console.log("message received \n" + raw_message);
      message = JSON.parse(raw_message.data);
      if (message.error) {
        return this.onError(message.error);
      } else {
        if (message.data == null) {
          message.data = {};
        }
        switch (message.name) {
          case 'initialize':
            this.initial_data = message.data || {};
            return this.run();
          case 'swapBodyReply':
            view_class_name = message.data.view_class_name;
            view_data = message.data.view_data;
            url = message.data.url;
            if (!(view_class_name in this.Views)) {
              return this.error("" + view_class_name + " is not a known View");
            }
            View = this.Views[view_class_name];
            view = new View(view_data);
            this.navigate(url);
            return this.page.swapBody(view);
          default:
            handler = this.messages[message.name];
            if (handler) {
              Mediator.emit(message.name, message.data);
              try {
                return handler(message.data, (function(_this) {
                  return function(response) {
                    if (response.error) {
                      return _this.onError(error);
                    } else if (response.reply) {
                      return _this.sendReply({
                        name: message.name,
                        data: reply
                      });
                    }
                  };
                })(this));
              } catch (_error) {
                error = _error;
                return this.onError(error);
              }
            } else {
              error = "Message:" + message.name + " is not supported";
              return console.error(error);
            }
        }
      }
    };

    Client.prototype.onClose = function() {
      return console.log('socket closed');
    };

    Client.prototype.send = function(message) {
      var keys, raw_message;
      if (message.data == null) {
        message.data = {};
      }
      keys = Object.keys(message);
      if (!((__indexOf.call(keys, 'name') >= 0) && (__indexOf.call(keys, 'data') >= 0) && (keys.length === 2))) {
        throw "Messages must have name and data attributes";
      }
      console.log("Sending message");
      console.log(message);
      raw_message = JSON.stringify(message);
      return this.socket.send(raw_message);
    };

    Client.prototype.onError = function(error) {
      return console.error(error);
    };

    return Client;

  })();

  Client.Mediator = Mediator;

  module.exports = Client;

}).call(this);
