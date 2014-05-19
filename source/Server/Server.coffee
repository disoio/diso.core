Http       = require('http')
Url        = require('url')
Path       = require('path')

EngineIO   = require('engine.io')
Connect    = require('connect')
Ecstatic   = require('ecstatic')
Signature  = require('cookie-signature')
Router     = require('diso.router')

RequestHandler = require('./RequestHandler')
SocketHandler  = require('./SocketHandler')
Mediator       = require('../Mediator')

class Server
  constructor : (options)->
    static_path     = options.static.path
    static_filepath = options.static.filepath
    @Actions        = options.Actions
    @Messages       = options.Messages
    @session_config = options.session
    @favicon_path   = options.favicon
    
    @static = Ecstatic(
      root        : static_filepath
      baseDir     : static_path
      handleError : false
    )
    
    @router = new Router()
    @router.route(options.routes)
    @router.notFound(@notFoundHandler)
    Mediator.router = @router

    # TODO: evaluate https://github.com/mozilla/node-client-sessions
    @cookie_parser = Connect.cookieParser()
    @session = Connect.session(@session_config)
    
    favicon     = Connect.favicon(@favicon_path)
    body_parser = Connect.bodyParser()
    
    connect = Connect()
      .use(@static)
      .use(favicon)
      .use(body_parser)
      .use(@cookie_parser)
      .use(@session)
      .use(@router)
      .use(@onRequest)
    
    @http_server = Http.createServer(connect)
  
  notFoundHandler : (request, response)=>
    if ('notFound' of @Actions)
      @Actions.notFound(request, response)
    else
      response.end("404")
    
  listen : (port)->
    @port = port
    @http_server.listen(@port)
    @socket_server = EngineIO.attach(@http_server)
    @socket_server.on('connection', @onConnection)
      
  onRequest : (request, response, next)=>
    request_handler = new RequestHandler(
      Actions  : @Actions
      request  : request
      response : response
      next     : next
    )
    request_handler.run()
  
  onConnection : (socket)=>
    @cookie_parser(socket.request, null, (error)=>
      key    = @session_config.key
      store  = @session_config.store
      secret = @session_config.secret
      cookie = socket.request.cookies[key]
      
      unless cookie
        console.error('no fuckin coookie wtf')
        return
      
      session_id = if (cookie.indexOf('s:') is 0)
        Signature.unsign(cookie.slice(2), secret)
      else
        cookie
        
      store.get(session_id, (error, session)=>
        if error
          console.log("error getting session #{error}")
        else
          socket_handler = new SocketHandler(
            Messages : @Messages
            Actions  : @Actions
            socket   : socket
            session  : session
          )
      )
    )

module.exports = Server