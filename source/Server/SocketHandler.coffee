# NPM dependencies
# ----------------
# [type-of-is](https://github.com/stephenhandley/type-of-is)  
Type = require('type-of-is')

# Local dependencies
# ------------------
# [Message](./Message.html) 
# [Strings](./Strings.html)
Message = require('../Shared/Message')
Strings = require('../Shared/Strings')


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
  # **jwt** : jwt object used for decoding / encoding tokens
  #           and for augmenting message with user_id / user
  #           when token is present
  # 
  # **message** : object of handlers for messages
  # 
  # **init_store** : the store used for getting data from 
  #                  initial http render for initializeReply
  #
  # **page_map** : the page map used for retrieving pages 
  #                for initializeReply
  constructor : (args)->
    @_socket     = args.socket
    @_models     = args.models
    @_messages   = args.messages 
    @_init_store = args.init_store
    @_jwt        = args.jwt
    @_page_map   = args.page_map

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

    _doReply = (reply_data)=>
      reply = message.reply(reply_data)
      @_sendMessage(reply)

    # this decodes the token (if present) and adds user_id or
    # user (if User.findForJwt is defined) to the message 
    # for use by next message handler 
    @_jwt.handleMessage(
      message  : message
      callback : (error)=>
        if error
          msg = "JWT processing failed"
          console.error("#{msg}:")
          console.error(error)
          _doReply(
            error : msg
          )

        else
          # certain messages handle internally by framework
          internal_messages = [
            'initialize', 'authenticate', 'find', 
            'subscribe', 'unsubscribe'
          ]

          if message.in(internal_messages)
            @["_onMessage_#{message.name}"](message)

          else
            handler = @_messages[message.name]

            if handler
              handler(
                message  : message
                callback : (error, data)=>
                  _doReply(
                    error : error
                    data  : data
                  )
              )

            else
              error = "Message:#{message.name} is not supported"
              console.error(error)
              _doReply(
                error : error
              )
    )

  _onClose : ()=>
    delete @constructor._sockets[@_socket.id]
          
  _onError : (error)=>
    console.error(error)
    #TODO handle error bettr

  # _onMessage_initialize
  # -----------
  # Respond to the initialize message with the id map and data 
  # used by the server side render of the requested page
  # 
  # **message** : message from client with page_key 
  _onMessage_initialize : (message)->
    data = message.data
    
    doReply = (error, data)=>
      reply = message.reply(
        error : error
        data  : data
      )
      @_sendMessage(reply)

    page_key = data.page_key
    init_data = @_init_store[page_key]

    unless data.reload
      return doReply(null, init_data)

    page = @_page_map.lookup(
      location : data.location
      user     : message.user
    )
    page.load((error, data)=>
      unless error
        init_data[Strings.PAGE_DATA] = data

      doReply(error, init_data)
    )

  # _onMessage_authenticate 
  # -------------
  # Delegates to an authenticate message in the user provided
  # messages object and then encodes a jwt token that the client
  # will include in subsequent request. 
  #
  # **message** : the message from client with auth data
  #
  # messages.authenticate should process the incoming message 
  # and respond with a user object having the following methods
  #
  # **id**         : required, returns unique identifier for user
  #
  # *saveToken*    : optional, saves token
  #
  # *tokenExpires* : optional, returns token expiry time
  #
  # TODO: considering moving some of the JWT related stuff into 
  #       JWT and save token prior to response? 
  _onMessage_authenticate : (message)->
    @_messages.authenticate(
      message  : message, 
      callback : (error, user)=>
        jwt_data = if error
          null
        else
          @_jwt.encode(user)

        reply = message.reply(
          error : error
          data  : jwt_data
        )
        @_sendMessage(reply)

        # after sending token, have user save it if its supported
        if (!error and Type(user.saveToken, Function))
          user.saveToken(
            token    : jwt_data.token
            callback : (error)->
              if error
                console.error(error)
                # error = new Error("Failed to save user token")
                # TODO: should send client message this failed?
                # @_sendError(error)
          )
    )

  # _onMessage_find
  # ---------------
  _onMessage_find : (message)->
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

  # _onMessage_subscribe
  # ----------
  # Allow client (socket) to subscribe to a given channel
  #
  # **topic**
  _onMessage_subscribe : (message)=>
    data = message.data
    topic = data.topic

  # _onMessage_unsubscribe
  # ----------
  # Allow client (socket) to subscribe to a given channel
  #
  # **topic**
  _onMessage_unsubscribe : (message)=>
    data = message.data
    topic = data.topic
   
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