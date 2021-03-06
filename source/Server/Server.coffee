# Core dependencies
# -----------------
# [http](http://nodejs.org/api/http.html)  
# [url](http://nodejs.org/api/url.html)  
# [path](http://nodejs.org/api/path.html)  
Http = require('http')
Url  = require('url')
Path = require('path')

# NPM dependencies
# ----------------
# [ws](https://github.com/einaros/ws)  
# [connect](https://github.com/senchalabs/connect)  
# [ecstatic](https://github.com/jesusabdullah/node-ecstatic)  
WS       = require('ws')
Connect  = require('connect')
Ecstatic = require('ecstatic')

# Local dependencies
# ------------------
# [RequestHandler](./RequestHandler.html)  
# [SocketHandler](./SocketHandler.html)  
# [Container](./Container.html)  
# [JWT](./JWT.html)  
# [PageMap](./PageMap.html)  
RequestHandler = require('./RequestHandler')
SocketHandler  = require('./SocketHandler')
Container      = require('./ServerContainer')
InitStore      = require('./InitStore')
JWT            = require('./JWT')
PageMap        = require('../Shared/PageMap')

# Server
# ======
# Handles HTTP and WebSocket connections from client
# 
# Initial request from the client is HTTP GET of some
# url. The Server delegates this request to 
# [RequestHandler](./RequestHandler.html), which in turn
# uses [PageMap](../PageMap.html) to find a page in 
# $args.pages matching a route name in $args.map. The page
# loads the data and views it needs and then renders itself and
# sends the result back to the client. It also stores that 
# data and a view id_map for later use by the 
# [SocketHandler](./SocketHandler.html).
#
# When the [Client](../Client.html) subsequently connects via 
# EngineIO/WebSocket, a instance of [SocketHandler](./SocketHandler.html) 
# is created to handle this persistent connection with the client. 
# The client is immediately sent an initializion payload consisting of 
# the stored data mentioned above. This is done in order to create an
# instance of the page on the client and sync it with the view hierarchy 
# previously rendered on the server prior to attaching event/behavior 
# handlers in the view.
#
# At this point, all subsequent communication is done via JSON over 
# the socket connection, and all rendering happens in the client. 
class Server
  # constructor
  # -----------
  # **name**       : name of the app/server
  #
  # **map**        : map of routes to pages
  #
  # **messages**   : class that will be instantiated to handle page request messages
  #
  # **models**     : Server side models used 
  #
  # **jwt_secret** : JSON web token secret
  #
  # **favicon**    : path for user's favicon
  # 
  # *static*    : Should have path and filepath keys mapping to the url path 
  #                 and filesystem path for static assets
  #
  # *container* : Override the default container used for pages. Default
  #                 implementation is [Container](./Container.html) If overriding, 
  #                 you must set container on server as well.
  #
  # *request*   : Override request handler
  #
  # *socket*    : Override socket handler
  #
  # *logo_url*  : Url for a site logo
  #
  constructor : (args = {})->
    required_args = ['name', 'map', 'messages', 'jwt_secret', 'favicon']
    for arg in required_args
      unless args[arg]
        throw new Error("diso.core.Server: Missing argument #{arg}")
    
    jwt_secret = args.jwt_secret
    map        = args.map
    favicon    = args.favicon
    @_name     = args.name
    @_models   = args.models

    Messages   = args.messages
    @_messages = new Messages()

    #optional args
    static_config = args.static

    if ('request' of args)
      RequestHandler = args.request

    if ('socket' of args)
      SocketHandler = args.socket

    container = if ('container' of args)
      args.container
    else
      new Container(
        logo_url  : args.logo_url
        site_name : args.name
      )

    init_store_config = if ('init_store' of args)
      args.init_store
    else
      { type : 'memory' }

    @_init_store = InitStore.create(init_store_config)

    # CONNECT MIDDLEWARE
    # ------------------
    _static = null
    if static_config
      # 1) Static asset handling
      _static = Ecstatic(
        root        : static_config.filepath
        baseDir     : static_config.path
        handleError : false
      )

    # 2) favicon
    if favicon
      favicon = Connect.favicon(favicon)

    # 3) body parser
    body_parser = Connect.bodyParser()

    # 4) JWT
    @_jwt = new JWT(
      secret : jwt_secret
      models : @_models
    )

    # 5) [PageMap](./PageMap.html) is used for routing / page lookup
    @_page_map = new PageMap(
      map    : map
      models : @_models
    )

    # 6) RequestHandler answers initial HTTP requests
    request_handler = new RequestHandler(
      init_store   : @_init_store
      container    : container
    )
    
    # Create the connect middleware pipeline
    connect = Connect()

    if _static
      connect.use(_static)

    if favicon
      connect.use(favicon)

    connect
      .use(body_parser)
      .use(@_jwt)
      .use(@_page_map)
      .use(request_handler)

    # create the server
    @_http_server = Http.createServer(connect)
  
  # listen
  # ------
  # Listen for HTTP connections on port number passed as argument
  # and setup the WebSocket listener
  #
  # **port** : port to listen on
  listen : (port)->
    @_http_server.listen(port)
    @_socket_server = new WS.Server(server : @_http_server)
    @_socket_server.on('connection', @_onSocketConnection)
  
  # _onSocketConnection
  # -------------------
  # Handle an incoming WebSocket connection
  #
  # **socket** :the socket this connection is made on
  _onSocketConnection : (socket)=>
    new SocketHandler(
      socket     : socket
      messages   : @_messages
      models     : @_models
      jwt        : @_jwt
      init_store : @_init_store
      page_map   : @_page_map
    )

module.exports = Server