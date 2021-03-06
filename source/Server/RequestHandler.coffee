# Local dependencies
# ------------------
# [parseAcceptHeader](./parseAcceptHeader.html)  
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
  # **container** : the container that handles page rendering
  constructor : (args)->
    @_init_store  = args.init_store
    @_container   = args.container

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
      console.error(error.stack)
      next("500")

    page = request.page

    @_container.load(
      page     : page
      callback : (error)=>
        if error
          return _onError(error)

        @_container.storeInitData(
          store    : @_init_store
          callback : (error)=>
            if error
              _onError(error)

            else
              try
                @_render(
                  request  : request
                  response : response
                )
              catch error
                _onError(error)
        )
    )

  # *INTERNAL METHODS*
  # ------------------
  
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