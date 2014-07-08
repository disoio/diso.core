Type = require('type-of-is')

_sendMessage = (options)->
  socket  = options.socket
  message = options.message

  unless Type(message, String)
    message = JSON.stringify(message)

  console.log("sending to socket=#{socket.id}")
  console.log(message)

  socket.send(message)

class SocketHandler
  @sockets : {}
  
  constructor : (options)->
    @socket  = options.socket
    @session = options.session
    @socket.session_id = @session.id
    @actions = options.actions
    
    Messages  = options.Messages
    @messages = new Messages(
      handler : @
    )
    
    Actions  = options.Actions
    @actions = new Actions(
      session : @session
    )
    
    unless (@socket.id of @constructor.sockets)
      @constructor.sockets[@socket.id] = @socket
      
    @socket.on('message', @onMessage)
    @socket.on('close', @onClose)
    @socket.on('error', @onError)
    
    @sendMessage(
      name : 'initialize'
      data : @session.initialization_data
    )
    delete @session.initialization_data
    
  onMessage : (raw_message)=>
    try 
      message = JSON.parse(raw_message)
    catch error
      console.error("Error parsing message: #{error}")
      return @sendMessage(error : "Message parse error")

    if message.error
      console.error("Client error : #{message.error}")
    else
      message.data ?= {}
      
    switch message.name
      when 'loadBody'
        params      = message.data.route.params
        action_name = message.data.route.name
        action      = @actions[action_name]

        if action
          try
            action(params, (response)=>
              if response?.error
                @sendError(response.error)
              else
                data = {
                  view_class_name : response.View.name
                  view_data       : response.data
                  url             : message.data.url
                }
                
                @sendReply(
                  name : message.name
                  data : data
                )
            )
          catch error
            console.error(error)
            @sendError("Render error")

        else
          error = "Action:#{action_name} is not supported"
          console.error(error)
          @sendError(error)

      else
        handler = @messages[message.name]

        console.log("Message received:\n#{JSON.stringify(message, null, 2)}")

        if handler
          try
            handler(message.data, (response)=>
              if response?.error
                @sendError(response.error)
              else if response
                @sendReply(
                  name : message.name
                  data : response
                )
            )
          catch error
            stack = new Error().stack
            console.log(error)
            console.error(stack)
            @sendError('Error processing message')

        else
          error = "Message:#{message.name} is not supported"
          console.error(error)
          @sendError(error)
  
  onClose : ()=>
    if (@socket.id of @constructor.sockets)
      delete @constructor.sockets[@socket.id]
      
    # TODO: close session
    
  onError : (error)=>
    console.error(error)
    @sendError("socket error")
      
  sendError : (error)=>
    @sendMessage(
      name  : 'error'
      error : error
    )
    
  sendReply : (message)=>
    message.name = "#{message.name}Reply"
    @sendMessage(message)
    
  sendMessage : (message)=>
    _sendMessage(
      socket  : @socket
      message : message
    )

  @sendMessageAll : (message)=>
    for id, socket of @sockets
      _sendMessage(
        socket : socket, 
        message : message
      )
  
module.exports = SocketHandler