(function() {
  var Connect, Container, Ecstatic, Http, PageMap, Path, RequestHandler, Server, SocketHandler, Store, Url, WS,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Http = require('http');

  Url = require('url');

  Path = require('path');

  WS = require('ws');

  Connect = require('connect');

  Ecstatic = require('ecstatic');

  RequestHandler = require('./RequestHandler');

  SocketHandler = require('./SocketHandler');

  Container = require('./ServerContainer');

  Store = require('./ServerStore');

  PageMap = require('../Shared/PageMap');

  Server = (function() {
    function Server(args) {
      var Messages, arg, body_parser, connect, container, favicon, map, page_map, request_handler, required_args, static_config, store, _i, _len, _static;
      if (args == null) {
        args = {};
      }
      this._onSocketConnection = __bind(this._onSocketConnection, this);
      required_args = ['name', 'map', 'messages', 'jwt_secret', 'favicon'];
      for (_i = 0, _len = required_args.length; _i < _len; _i++) {
        arg = required_args[_i];
        if (!args[arg]) {
          throw new Error("diso.core.Server: Missing argument " + arg);
        }
      }
      map = args.map;
      this._jwt_secret = args.jwt_secret;
      favicon = args.favicon;
      this._name = args.name;
      Messages = args.messages;
      this._messages = new Messages();
      static_config = args["static"];
      if ('request' in args) {
        RequestHandler = args.request;
      }
      if ('socket' in args) {
        SocketHandler = args.socket;
      }
      container = 'container' in args ? args.container : new Container({
        logo_url: args.logo_url,
        site_name: args.name
      });
      store = 'store' in args ? args.store : new Store();
      this._init_store = {};
      _static = null;
      if (static_config) {
        _static = Ecstatic({
          root: static_config.filepath,
          baseDir: static_config.path,
          handleError: false
        });
      }
      if (favicon) {
        favicon = Connect.favicon(favicon);
      }
      body_parser = Connect.bodyParser();
      page_map = new PageMap({
        map: map,
        store: store
      });
      request_handler = new RequestHandler({
        messages: this._messages,
        cache: this._cache,
        init_store: this._init_store,
        container: container
      });
      connect = Connect();
      if (_static) {
        connect.use(_static);
      }
      if (favicon) {
        connect.use(favicon);
      }
      connect.use(body_parser).use(page_map).use(request_handler);
      this._http_server = Http.createServer(connect);
    }

    Server.prototype.listen = function(port) {
      this._http_server.listen(port);
      this._socket_server = new WS.Server({
        server: this._http_server
      });
      return this._socket_server.on('connection', this._onSocketConnection);
    };

    Server.prototype._onSocketConnection = function(socket) {
      return new SocketHandler({
        socket: socket,
        messages: this._messages,
        jwt_secret: this._jwt_secret,
        init_store: this._init_store
      });
    };

    return Server;

  })();

  module.exports = Server;

}).call(this);
