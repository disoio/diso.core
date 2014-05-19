$        = require('jquery')
EngineIO = require('engine.io-client')
Router   = require('diso.router')

Mediator = require('./Mediator')

has_run = false

class Client
  @run : (options)->
    unless has_run
      client = new Client(options)
      client.run()
      has_run = true
  
  constructor : (options)->
    @Views = options.Views
    routes = options.routes
    
    Messages = options.Messages
    @messages = new Messages(
      client : @
    )

    @router = new Router()
    @router.route(routes)
    
    Mediator.client = @
    Mediator.router = @router
    Mediator.on('error', (message)=>
      @onError(message.error)
    )
    
    socket_url = "ws://#{window.location.host}"
    @socket = new EngineIO(socket_url)
    @socket.onopen    = @onOpen
    @socket.onmessage = @onMessage
    @socket.onclose   = @onClose
    
    @dom_ready    = false
    @has_run      = false
    @initial_data = null
    
    $(document).ready(()=>
      @dom_ready = true      
      @run()
    )
  
  ###########
  # HISTORY #
  ###########
  
  # using bare html5 history api fallback to full page load .. don't wanna
  # use hash based routing because it looks like shit
  # http://caniuse.com/#search=history
  # http://diveintohtml5.info/history.html
  
  setupHistory : ()->
    if @supportsHistory()
      $(window).on('popstate', @onPopState)
  
  supportsHistory : ()->
    !!(window.history and window.history.pushState)
  
  navigate : (url)->
    if @supportsHistory()
      window.history.pushState(null, null, url)
    else
      window.location = url
    
  onPopState : ()=>
    @swapBody(url : document.location)
  
  #########
  # VIEWS #
  #########
  
  swapBody : (options)->
    if ('url' of options)
      options.route = @router.match(url : options.url)
    else if ('route' of options)
      options.url = @router.format(options.route)
    else
      throw "Must pass url or params to swap body"

    @send(
      name : 'swapBody'
      data : options
    )
      
  # This is called after dom is ready and socket has
  # recieved the initial data
  run : ()=>
    if @has_run
      return
      
    if (@dom_ready and @initial_data)
      @setupHistory()
      
      body = $('body')
      page_view_class_name = body.attr('data-page-type')
      body_view_class_name = body.attr('data-body-type')
    
      @page = null
      if (page_view_class_name of @Views) and (body_view_class_name of @Views)
        Page = @Views[page_view_class_name]
        Body = @Views[body_view_class_name]
          
        # TODO: add current route for completeness
        @page = Page.create(
          Body   : Body
          data   : @initial_data.view_data
          id_map : @initial_data.id_map
          url    : document.location
        )
        @initial_data = null
        
        if ('clientReady' of @messages)
          @messages.clientReady()
        
      @has_run = true
      
  #############
  # WEBSOCKET #
  #############
  
  onOpen : ()=>
  
  onMessage : (raw_message)=>
    console.log("message received \n#{raw_message}")
    message = JSON.parse(raw_message.data)
    
    if message.error
      @onError(message.error)
    
    else
      message.data ?= {}
      
      switch (message.name)
        when 'initialize'
          @initial_data = message.data || {}
          @run()
        
        when 'swapBodyReply'
          view_class_name = message.data.view_class_name
          view_data       = message.data.view_data
          url             = message.data.url
          
          unless view_class_name of @Views
            return @error("#{view_class_name} is not a known View")

          View = @Views[view_class_name]
          view = new View(view_data)
          @navigate(url)
          @page.swapBody(view)
          
        else           
          handler = @messages[message.name]

          if handler
            Mediator.emit(message.name, message.data)
            
            try
              handler(message.data, (response)=>
                if response.error
                  @onError(error)
                else if response.reply
                  @sendReply(
                    name : message.name
                    data : reply
                  )
              )
            catch error
              @onError(error)
              
          else
            error = "Message:#{message.name} is not supported"
            console.error(error)
  
  onClose : ()=>
    console.log('socket closed')
  
  send: (message) =>
    message.data ?= {}
    
    keys = Object.keys(message)
    unless (('name' in keys) and ('data' in keys) and (keys.length is 2))    
      throw "Messages must have name and data attributes"
      
    console.log("Sending message")
    console.log(message)
      
    raw_message = JSON.stringify(message)
    @socket.send(raw_message)
  
  onError : (error)->
    console.error(error)

Client.Mediator = Mediator

module.exports = Client