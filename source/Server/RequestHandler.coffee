# Local dependencies
# ------------------
# [ServerStore](./ServerStore.html)  
# [parseAcceptHeader](./parseAcceptHeader.html)  
ServerStore = require('./ServerStore')
parseAcceptHeader = require('./parseAcceptHeader')

# Supported rendering formats
FORMAT = {
  html : 'text/html',
  json : 'application/json',
  text : 'text/plain' 
}

# RequestHandler
# ==============
# This class handles http requests received by the server
class RequestHandler
  # constructor
  # -----------
  # **init_store** : the cache where initial render / idmap data is 
  #                  stored for later retrieval to answer initialize 
  #                  socket message
  #
  # **messages** : the user specified messages handler passed to the server
  #
  # **container** : the container that handles page rendering
  constructor : (args)->
    @_init_store = args.init_store
    messages     = args.messages
    @_container  = args.container

    # Store used by container/page to fetch data
    # Basically just a pass through to messages
    @_store = new ServerStore(
      messages : messages
    )

  # handle
  # ------
  # this function is called by the [connect](https://github.com/senchalabs/connect) 
  # middleware pipeline on server. It uses the container to 
  # handle the page thats been attached to the request, caches 
  # data to be passed down to the client during the socket 
  # setup and initializing phase, and then calls render to send
  # the response
  #
  # **request,response,next**: the standard connect middleware trio
  handle : (request, response, next)->
    _onError = (error)->
      console.error(error)
      next("500")

    @_container.load(
      page     : request.page
      store    : @_store
      callback : (error)=>
        if error
          return _onError(error)

        # persist the init data so can get later and 
        # send to client for initializeReply
        # TODO: CLEANUP 4 2 SCALE PLZ 4 WEB
        @_init_store[@_container.pageKey()] = @_container.initData()

        try
          @_render(
            request  : request
            response : response
          )
        catch error
          _onError(error)  
    )

  # INTERNAL METHODS
  # ----------------
  
  # _responseFormat
  # ---------------
  # Finds the response format for an incoming request
  #
  # **request** : the http request to find the response format for
  _responseFormat : (request)->
    accepts = request.headers['Accept']

    if accepts
      parsed_accepts = parseAcceptHeader(accepts)  
      
      for accept in parsed_accepts
        type = "#{accept.type}/#{accept.subtype}"
        types = (v for k,v of FORMAT)
        if (type in types)
          return [k, type]
    
    ['html', FORMAT.html]
  
  # _render
  # -------
  # Have the container render the page for the given request
  #
  # **request** : the http request being handled
  #
  # **response** : the http response that will be used to 
  #                answer the request
  _render : (args)=>
    request  = args.request
    response = args.response

    [format, content_type] = @_responseFormat(request)      

    headers = @_container.headers()
    headers['Content-Type'] = content_type
    status = @_container.status() || 200
    
    body = @_container[format]()

    response.writeHead(status, headers)
    response.end(body)
      
module.exports = RequestHandler