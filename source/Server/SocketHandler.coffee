# NPM dependencies
# ------------------
# [type-of-is](https://github.com/stephenhandley/type-of-is)  
# [jsonwebtoken](https://github.com/auth0/node-jsonwebtoken)  
Type = require('type-of-is')
JWT  = require('jwt-simple')

# Local dependencies
# ------------------
# [Message](./Message.html)  
Message = require('../Shared/Message')

# strings used to by JWT
TOKEN = {
  Expires : 'exp'
  Issuer  : 'iss'
}

# RequestHandler
# ==============
# This class handles socket requests received by the server
# Aside from the initalize and authenticate messages, it 
# delegates directly to the user specified messages object, 
# calling methods with the name of the sent messages to handle
# processing.
# 
class SocketHandler
  # sockets keyed by socket id
  @_sockets : {}
  
  # constructor 
  # ----------
  # **socket** : the socket 
  #
  # **models** : server side models
  # 
  # **jwt_secret** : jwt_secret used for decoding token
  # 
  # **message** : object of handlers for messages
  # 
  # **init_store** : the store used for getting data from 
  #                  initial http render for initializeReply
  constructor : (args)->
    @_socket     = args.socket
    @_models     = args.models
    @_jwt_secret = args.jwt_secret
    @_messages   = args.messages 
    @_init_store = args.init_store
    
    @constructor._sockets[@_socket.id] = @_socket
      
    @_socket.on('message', @_onMessage)
    @_socket.on('close', @_onClose)
    @_socket.on('error', @_onError)
  
  # *INTERNAL METHODS*
  # ------------------

  # _onMessage
  # ----------
  # Event handler for message from socket
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
    
    # initialize and authenticate messages are handled by framework
    if message.in(['initialize', 'authenticate', 'find'])
      @["_#{message.name}"](message)

    else
      handler = @_messages[message.name]

      if handler
        handler(
          message  : message
          callback : (error, data)=>
            reply = message.reply(
              error : error
              data  : data
            )
            @_sendMessage(reply)
        )

      else
        error = "Message:#{message.name} is not supported"
        console.error(error)
        reply = message.reply(
          error : error
        )
        @_sendMessage(reply)

  _onClose : ()=>
    delete @constructor._sockets[@_socket.id]
          
  _onError : (error)=>
    console.error(error)
    #TODO handle error bettr

  # _initialize
  # -----------
  # Respond to the initialize message with the id map and data 
  # used by the server side render of the requested page
  # 
  # **message** : message from client with page_key 
  _initialize : (message)->
    page_key   = message.data.page_key
    init_data = @_init_store[page_key]
    reply     = message.reply(data : init_data)
    @_sendMessage(reply)

  # _authenticate 
  # -------------
  # Delegates to an authenticate message in the user provided
  # messages object and then encodes a jwt token that the client
  # will include in subsequent request. 
  # **message** : the message from client with auth data
  #
  # messages.authenticate should process the incoming message 
  # and respond with a user object having the following methods
  # **id**         : required, returns unique identifier for user
  # *saveToken*    : optional, saves token
  # *tokenExpires* : optional, returns token expiry time
  _authenticate : (message)->
    @_messages.authenticate(
      message  : message, 
      callback : (error, user)=>
        unless error             
          body = {}
          body[TOKEN.Issuer] = user.id()
          
          expires = if Type(user.tokenExpires, Function)
            user.tokenExpires()
          else
            null

          if expires
            body[TOKEN.Expires] = expires

          token = JWT.encode(body, @_jwt_secret)

          data = {
            token   : token
            expires : expires
            user    : user
          }

        reply = message.reply(
          error : error
          data  : data
        )
        @_sendMessage(reply)

        # after sending token, have user save it if its supported
        if (!error and Type(user.saveToken, Function))
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

  # _find
  # -----
  _find : (message)->
    data = message.data
    
    _id        = data._id
    model_name = data.model

    _reply = (reply_data)=>
      reply = message.reply(reply_data)
      @_sendMessage(reply)

    _error = (error)=>
      console.error(error)
      _reply(
        data  : null
        error : new Error("Model not found")
      )

    Model = @_models[model_name]
    unless Model
      error = new Error("Could not find model named '#{model_name}'")
      return _error(error)

    Model.find(
      _id      : _id
      callback : (error, model)->
        if error
          return _error(error)

        if model
          _reply(
            error : null
            data  : { model : model }
          )
        else
          error = new Error("Could not find #{model_name} with id #{_id}")
          _error(error)
    )

  # _addUserIdFromToken
  # -------------------
  # If message has token, decode it and add the associated user id
  # to the message for later processing
  #
  # **message** : message to process
  _addUserIdFromToken : (message)=>
    if message.token
      body = JWT.decode(message.token, @_jwt_secret)

      # check token expiration
      expires = body[TOKEN.Expires]
      expired = if expires
        now = Date.now()
        (expires < now)
      else
        false

      unless expired
        message.user_id = body[TOKEN.Issuer]
   
  # _sendMessage
  # ------------
  # Send a message to the client
  #
  # **message** : message to send
  _sendMessage : (message)=>
    raw_message = message.stringify()
    console.log("SND #{raw_message}")
    @_socket.send(raw_message)

  # _sendMessageAll
  # ---------------
  # Send a message to all clients
  #
  # **message** : message to send
  _sendMessageAll : (message)=>
    for id, socket of @constructor._sockets
      raw_message = message.stringify()
      socket.send(raw_message)
        
module.exports = SocketHandler