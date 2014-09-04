# NPM dependencies
# ------------------
# [type-of-is](https://github.com/stephenhandley/type-of-is)  
# [jsonwebtoken](https://github.com/auth0/node-jsonwebtoken)  
Type = require('type-of-is')
JWT  = require('jwt-simple')

# Local dependencies
# ------------------
# [Message](../Shared/Message.html)  
Message = require('../Shared/Message')

# strings used to by JWT
TOKEN = {
  EXPIRES : 'exp'
  ISSUER  : 'iss'
}

class SocketHandler
  @_sockets : {}
  
  constructor : (args)->
    @_socket     = args.socket
    @_jwt_secret = args.jwt_secret
    @_messages   = args.messages 
    @_init_store = args.init_store
    
    @constructor._sockets[@_socket.id] = @_socket
      
    @_socket.on('message', @_onMessage)
    @_socket.on('close', @_onClose)
    @_socket.on('error', @_onError)
    
  _onMessage : (raw_message)=>
    console.log("RCV #{raw_message}")

    message = Message.parse(raw_message)

    if message.isError()
      console.error("Client error: #{message.error}")
      # TODO: how to best handle client errors on server
      return 

    # this decodes the token (if present) and adds user_id to 
    # message for use by handler 
    @_addUserIdFromToken(message)
    
    if message.in(['initialize', 'authenticate'])
      @["_#{message.name}"](message)

    else
      handler = @_messages[message.name]

      if handler
        handler(
          message  : message
          callback : (response)=>
            if response?.error
              @_sendError(response.error)
            else if response
              reply = message.reply(response)
              @_sendMessage(reply)
        )

      else
        error = "Message:#{message.name} is not supported"
        console.error(error)
        @_sendError(error)

  _initialize : (message)->
    page_key   = message.data.page_key
    init_data = @_init_store[page_key]
    reply     = message.reply(init_data)
    @_sendMessage(reply)

  _authenticate : (message)->
    # @_messages.authenticate should process the incoming message 
    # and respond with a user object having the following methods
    # **id**           : required, returns unique identifier for user
    # **saveToken**    : optional, saves token
    # **tokenExpires** : optional, returns token expiry time

    @_messages.authenticate(
      message  : message, 
      callback : (response)=>
        if response.error
          return @_sendError(response.error)
        
        user = response.user
        body = {}
        body[TOKEN.ISSUER] = user.id()
        
        expires = if Type(user.tokenExpires, Function)
          user.tokenExpires()
        else
          null

        if expires
          body[TOKEN.EXPIRES] = expires

        token = JWT.encode(body, @_jwt_secret)

        reply = message.reply({
          token   : token
          expires : expires
          user    : user
        })

        @_sendMessage(reply)

        # after sending token, have user save it if its supported
        if Type(user.saveToken, Function)
          user.saveToken(
            token    : token
            callback : (error)->
              if error
                console.error(error)
                # error = new Error("Failed to save user token")
                # TODO: should send client message this failed?
                # @_sendError(error)
          )
    )
  
  _addUserIdFromToken : (message)=>
    if message.token
      body = JWT.decode(message.token, @_jwt_secret)

      # check token expiration
      expires = body[TOKEN.EXPIRES]
      expired = if expires
        now = Date.now()
        (expires < now)
      else
        false

      unless expired
        message.user_id = body[TOKEN.ISSUER]

  _onClose : ()=>
    delete @constructor._sockets[@_socket.id]
          
  _onError : (error)=>
    console.error(error)
    #TODO handle error
  
  # TODO: Error's should have some record of inbound 
  #       message that resulted in the error.. 
  _sendError : (error)=>
    message = Message.error(error)
    @_sendMessage(message)
    
  _sendMessage : (message)=>
    raw_message = message.stringify()
    console.log("SND #{raw_message}")
    @_socket.send(raw_message)

  _sendMessageAll : (message)=>
    for id, socket of @constructor._sockets
      raw_message = message.stringify()
      socket.send(raw_message)
        
module.exports = SocketHandler