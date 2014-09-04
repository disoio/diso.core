(function() {
  var $, Client, Container, Mediator, Message, PageMap, Store, Type, constructed,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $ = require('jquery');

  Type = require('type-of-is');

  Container = require('./ClientContainer');

  Store = require('./ClientStore');

  Mediator = require('../Shared/Mediator');

  Message = require('../Shared/Message');

  PageMap = require('../Shared/PageMap');

  constructed = false;

  Client = (function() {
    Client.prototype._reconnect = {
      working: false,
      attempts: 0,
      max_timeout: 5000,
      min_timeout: 1000,
      disabled: false
    };

    Client.prototype.__auth = null;

    Client.prototype._dom_ready = false;

    Client.prototype._socket_open = false;

    function Client(args) {
      this._reconnectDelay = __bind(this._reconnectDelay, this);
      this._onClose = __bind(this._onClose, this);
      this._onError = __bind(this._onError, this);
      this._onMessage = __bind(this._onMessage, this);
      this._onOpen = __bind(this._onOpen, this);
      this._connect = __bind(this._connect, this);
      this.send = __bind(this.send, this);
      this._run = __bind(this._run, this);
      var error, k, store, v, _i, _len, _ref, _ref1;
      if (constructed) {
        throw new Error("Client already constructed");
      } else {
        constructed = true;
      }
      _ref = ['name', 'map'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        k = _ref[_i];
        if (!(k in args)) {
          error = new Error("Client missing required argument: " + k);
          throw error;
        }
      }
      this._name = args.name;
      store = 'store' in args ? args.store : new Store();
      this._container = 'container' in args ? args.container : new Container({
        map: args.map,
        store: store
      });
      if ('models' in args) {
        Message.setModels(args.models);
      }
      if ('reconnect' in args) {
        if (args.reconnect === false) {
          this._reconnect.disabled = true;
        } else {
          _ref1 = args.reconnect;
          for (k in _ref1) {
            v = _ref1[k];
            this._reconnect[k] = v;
          }
        }
      }
      Mediator.delegate({
        'send': this,
        'goto': this._container
      });
      if ('WebSocket' in window) {
        this._connect();
      } else {
        this._clientError("WebSockets not supported by browser");
      }
      $(document).ready((function(_this) {
        return function() {
          _this._dom_ready = true;
          Mediator.emit('client:domready');
          return _this._init();
        };
      })(this));
    }

    Client.prototype.logout = function() {
      return this._auth(null);
    };

    Client.prototype._clientError = function(message) {
      var error;
      error = new Error(message);
      return Mediator.emit('client:error', error);
    };

    Client.prototype._init = function() {
      var page_key;
      if (!(this._dom_ready && this._socket_open)) {
        return;
      }
      page_key = this._container.pageKey();
      return this.send({
        name: 'initialize',
        data: {
          page_key: page_key
        }
      });
    };

    Client.prototype._run = function(init_data) {
      var error;
      error = this._container.sync(init_data);
      if (error) {
        return this._clientError(error);
      } else {
        return Mediator.emit('client:ready');
      }
    };

    Client.prototype._auth = function(auth) {
      var checkAuthExpiration, key, raw_auth, removeAuth;
      key = "" + this._name + ":auth";
      removeAuth = (function(_this) {
        return function() {
          localStorage.removeItem(key);
          return _this.__auth = null;
        };
      })(this);
      checkAuthExpiration = (function(_this) {
        return function() {
          var expired;
          if (!_this.__auth) {
            return;
          }
          expired = _this.__auth.expires && (_this.__auth.expires < Date.now());
          if (expired) {
            return removeAuth();
          }
        };
      })(this);
      if (arguments.length === 1) {
        if (auth) {
          this.__auth = auth;
          checkAuthExpiration();
          if (this.__auth) {
            raw_auth = JSON.stringify(this.__auth);
            return localStorage.setItem(key, raw_auth);
          }
        } else {
          return removeAuth();
        }
      } else {
        if (!this.__auth) {
          raw_auth = localStorage.getItem(key);
          if (raw_auth) {
            this.__auth = JSON.parse(raw_auth);
          }
        }
        checkAuthExpiration();
        return this.__auth;
      }
    };

    Client.prototype.send = function(message) {
      var auth, raw_message;
      if (!Type(message, Message)) {
        message = new Message(message);
      }
      auth = this._auth();
      message.token = auth ? auth.token : null;
      raw_message = message.stringify();
      Mediator.emit('client:send', raw_message);
      return this._socket.send(raw_message);
    };

    Client.prototype._connect = function() {
      var event, socket_url;
      socket_url = "ws://" + window.location.host;
      this._socket = new WebSocket(socket_url);
      this._socket.onopen = this._onOpen;
      this._socket.onmessage = this._onMessage;
      this._socket.onclose = this._onClose;
      this._socket.onerror = this._onError;
      event = this._reconnect.working ? 'reconnecting' : 'connecting';
      return Mediator.emit("client:" + event);
    };

    Client.prototype._onOpen = function() {
      var event;
      event = this._reconnect.working ? (this._reconnect.attempts = 0, this._reconnect.working = false, 'reconnected') : (this._socket_open = true, this._init(), 'connected');
      Mediator.emit('client:open');
      return Mediator.emit("client:" + event);
    };

    Client.prototype._onMessage = function(event) {
      var message, message_event, message_event_name, message_event_name_id, raw_message;
      raw_message = event.data;
      Mediator.emit('client:receive', raw_message);
      message = Message.parse(raw_message);
      if (message["in"](['initializeReply', 'authenticateReply'])) {
        this["_" + message.name](message);
      }
      message_event = 'message';
      message_event_name = "" + message_event + ":" + message.name;
      message_event_name_id = "" + message_event_name + ":id:" + message.id;
      Mediator.emit(message_event, message);
      Mediator.emit(message_event_name, message);
      return Mediator.emit(message_event_name_id, message);
    };

    Client.prototype._initializeReply = function(message) {
      return this._run(message.data);
    };

    Client.prototype._authenticateReply = function(message) {
      var data;
      data = message.data;
      Mediator.emit("client:authenticated", data);
      delete data.user;
      return this._auth(data);
    };

    Client.prototype._onError = function(error) {
      console.error(error);
      return this._clientError("Socket error");
    };

    Client.prototype._onClose = function() {
      var delay;
      Mediator.emit('client:close');
      if (!this._reconnect.disabled) {
        delay = this._reconnectDelay();
        this._reconnect.attempts += 1;
        return setTimeout(this._connect, delay);
      }
    };

    Client.prototype._reconnectDelay = function() {
      var attempts, base, max_timeout, min_timeout, spread, timeout;
      spread = Math.random() + 1;
      min_timeout = this._reconnect.min_timeout;
      base = 2;
      max_timeout = this._reconnect.max_timeout;
      attempts = this._reconnect.attempts;
      timeout = spread * min_timeout * Math.pow(base, attempts);
      return Math.min(timeout, max_timeout);
    };

    return Client;

  })();

  Client.Mediator = Mediator;

  module.exports = Client;

}).call(this);
