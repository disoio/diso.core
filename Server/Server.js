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
      this._onConnection = __bind(this._onConnection, this);
      this._onRequest = __bind(this._onRequest, this);
      var Messages, body_parser, connect, container, favicon, map, page_map, static_config, store, _static;
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
      this._request_handler = new RequestHandler({
        messages: this._messages,
        cache: this._cache,
        init_store: this._init_store,
        container: container
      });
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
      connect = Connect();
      if (_static) {
        connect.use(_static);
      }
      if (favicon) {
        connect.use(favicon);
      }
      connect.use(body_parser).use(page_map).use(this._onRequest);
      this._http_server = Http.createServer(connect);
    }

    Server.prototype.listen = function(port) {
      this._http_server.listen(port);
      this._socket_server = new WS.Server({
        server: this._http_server
      });
      return this._socket_server.on('connection', this._onConnection);
    };

    Server.prototype._onRequest = function(request, response, next) {
      return this._request_handler.run({
        request: request,
        response: response,
        next: next
      });
    };

    Server.prototype._onConnection = function(socket) {
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
