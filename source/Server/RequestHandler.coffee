# Supported rendering formats
FORMAT = {
  html : 'text/html',
  json : 'application/json',
  text : 'text/plain' 
}

parseAcceptHeader = require('./parseAcceptHeader') 

class ServerStore
  constructor : (args)->
    @messages = args.messages

  get : (args)->
    message  = args.message
    callback = args.callback 

# RequestHandler
# ==============
# 
class RequestHandler
  constructor : (args)->
    @_init_store = args.init_store
    messages     = args.messages
    @_container  = args.container

    @_store = new ServerStore(
      messages : messages
    )
    
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

  run : (args)->
    request  = args.request
    response = args.response
    next     = args.next

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
    
      
module.exports = RequestHandler