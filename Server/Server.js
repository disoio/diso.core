(function() {
  var Connect, Ecstatic, EngineIO, Http, Mediator, Path, RequestHandler, Router, Server, Signature, SocketHandler, Url,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Http = require('http');

  Url = require('url');

  Path = require('path');

  EngineIO = require('engine.io');

  Connect = require('connect');

  Ecstatic = require('ecstatic');

  Signature = require('cookie-signature');

  Router = require('diso.router');

  RequestHandler = require('./RequestHandler');

  SocketHandler = require('./SocketHandler');

  Mediator = require('../Mediator');

  Server = (function() {
    function Server(options) {
      this.onConnection = __bind(this.onConnection, this);
      this.onRequest = __bind(this.onRequest, this);
      this.notFoundHandler = __bind(this.notFoundHandler, this);
      var body_parser, connect, favicon, static_filepath, static_path;
      static_path = options["static"].path;
      static_filepath = options["static"].filepath;
      this.Actions = options.Actions;
      this.Messages = options.Messages;
      this.session_config = options.session;
      this.favicon_path = options.favicon;
      this["static"] = Ecstatic({
        root: static_filepath,
        baseDir: static_path,
        handleError: false
      });
      this.router = new Router();
      this.router.route(options.routes);
      this.router.notFound(this.notFoundHandler);
      Mediator.router = this.router;
      this.cookie_parser = Connect.cookieParser();
      this.session = Connect.session(this.session_config);
      favicon = Connect.favicon(this.favicon_path);
      body_parser = Connect.bodyParser();
      connect = Connect().use(this["static"]).use(favicon).use(body_parser).use(this.cookie_parser).use(this.session).use(this.router).use(this.onRequest);
      this.http_server = Http.createServer(connect);
    }

    Server.prototype.notFoundHandler = function(request, response) {
      if ('notFound' in this.Actions) {
        return this.Actions.notFound(request, response);
      } else {
        return response.end("404");
      }
    };

    Server.prototype.listen = function(port) {
      this.port = port;
      this.http_server.listen(this.port);
      this.socket_server = EngineIO.attach(this.http_server);
      return this.socket_server.on('connection', this.onConnection);
    };

    Server.prototype.onRequest = function(request, response, next) {
      var request_handler;
      request_handler = new RequestHandler({
        Actions: this.Actions,
        request: request,
        response: response,
        next: next
      });
      return request_handler.run();
    };

    Server.prototype.onConnection = function(socket) {
      return this.cookie_parser(socket.request, null, (function(_this) {
        return function(error) {
          var cookie, key, secret, session_id, store;
          key = _this.session_config.key;
          store = _this.session_config.store;
          secret = _this.session_config.secret;
          cookie = socket.request.cookies[key];
          if (!cookie) {
            console.error('no fuckin coookie wtf');
            return;
          }
          session_id = cookie.indexOf('s:') === 0 ? Signature.unsign(cookie.slice(2), secret) : cookie;
          return store.get(session_id, function(error, session) {
            var socket_handler;
            if (error) {
              return console.log("error getting session " + error);
            } else {
              return socket_handler = new SocketHandler({
                Messages: _this.Messages,
                Actions: _this.Actions,
                socket: socket,
                session: session
              });
            }
          });
        };
      })(this));
    };

    return Server;

  })();

  module.exports = Server;

}).call(this);
