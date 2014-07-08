Url   = require('url')

Utils = require('./Utils')

FORMAT = {
  html : 'text/html',
  json : 'application/json',
  text : 'text/plain' 
}

class RequestHandler
  constructor : (options)->
    @request  = options.request
    @response = options.response
    @next     = options.next
    
    @Actions = options.Actions
    if 'Page' of @Actions
      @Page = @Actions.Page
    
    @parsed_url = Url.parse(@request.url, true)
    
    @actions = new @Actions(
      session : @request.session
    )
    
  params : ()->
    @request.route.params
    
  method : ()->
    @request.method
  
  actionName : ()->
    @request.route.name
    
  Page : null
  
  path : ()->
    @parsed_url.pathname.slice(1)
  
  query : ()->
    @parsed_url.query
    
  # keep it simple and respond with HTML unless JSON is explicitly requested
  responseType : ()->
    accepts = @request.headers['Accept']

    if accepts      
      for accept in Utils.parseAcceptHeader(accepts)
        type = "#{accept.type}/#{accept.subtype}"
        types = v for k,v of FORMAT
        if (type in types)
          return type
    
    FORMAT.html
  
  isXHR : ()->
    req_with = @request.headers['X-Requested-With'] || ''
    req_with is 'xmlhttprequest'
    
  render: (options)->
    format = @responseType()
    
    body = if format is FORMAT.json
      JSON.stringify(options.data)
    else
      unless options.View
        throw "Action callback doesn't specify view"
      
      View = options.View
      data = options.data || {}
    
      Page = if options.Page
        options.Page
      else if @Page
        @Page
      else
        null
      
      view = if Page
        new Page(
          Body  : View
          route : @actionName()
          data  : data
          url   : @request.url
        )
      else
        new View(data)
      
      @request.session.initialization_data = {
        view_data  : data
        id_map     : view.idMap()
      }

      if format is FORMAT.text
        view.text()
      else
        view.html()

    headers = options.headers || {}
    headers['Content-Type'] = format
    status = options.status || 200
    
    @response.writeHead(status, headers)
    @response.end(body)
  
  run : ()->
    action_name = @actionName()
    action = @actions[action_name]
    
    if action
      try
        action(@params(), (response)=>
          if response.error
            @next(response.error)
          else
            @render(response)
        )
      catch error
        console.error(error)
        stack = if error.stack
          error.stack
        else
          (new Error()).stack
        console.error(stack)
        @next("Error running action")
      
    else
      error = "Action:#{action_name} is not supported"
      console.error(error)
      @next(error)
      
module.exports = RequestHandler