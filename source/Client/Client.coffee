# NPM dependencies
# ------------------
# [jquery](https://github.com/jquery/jquery)  
# [type-of-is](https://github.com/stephenhandley/type-of-is)
# [EventEmitter](http://nodejs.org/api/events.html#events_class_events_eventemitter)  
$              = require('jquery')
Type           = require('type-of-is')
{EventEmitter} = require('events')

# Local dependencies
# ------------------
# [ClientContainer](./ClientContainer.html)  
# [Mediator](./Mediator.html)  
# [Message](./Message.html)  
# [PageMap](./PageMap.html)  
Container = require('./ClientContainer')
Mediator  = require('../Shared/Mediator')
Message   = require('../Shared/Message')
PageMap   = require('../Shared/PageMap')

# This is set to true once the constructor has been called
constructed = false

# Client
# ======
# An instance of Client serves as the entry point for all code run 
# in the user's browser. It handles sending and receiving data 
# to and from the server, manages navigation, history and page
# transitions. The Client uses [Mediator](../Mediator.html) for
# pubsub-style message broadcast between itself and the views.
#
# In its constructor, the client opens a WebSocket connection to 
# the server. After this connection is successfully opened, the 
# client sends an **initialize** message to the server, and then
# waits for 2 things to happen
# 1. **domready** event fires in browser
# 2. **initializeReply** message arrives from server
#
# After those both happen then the **_setup** method takes care of syncing
# the current page with the dom. The page's views then handle user 
# interaction and use the client's **send** method (via the [Mediator](./Mediator.html)) 
# to send data to and from the server
class Client

  # Configuration for client reconnecting when WebSocket loses connectivity
  _reconnect : {
    working     : false
    attempts    : 0
    max_timeout : 5000
    min_timeout : 1000
    disabled    : false
  }

  # auth is of the form
  # {
  #   token   : <jwt token>
  #   expires : <optional token expiration time>
  # }
  __auth : null

  # true after domready event fired
  _dom_ready : false

  # true when the socket is open
  _socket_open : false

  # event emitter used as pubsub bus
  _pubsub : null


  # constructor
  # -----------
  # **map** : map of routes to pages  
  # 
  # **models**  : Client side models.client will traverse the message data 
  #               and inflate plain json objects into instances of those 
  #               models using the $model attr 
  # 
  # *reconnect* : If false, disables autoreconnect, otherwise should
  #                 be object that can specify the following configuration
  #                 params: *max_timeout*, *min_timeout*  
  #
  # *container* : Override the default container used for pages. Default
  #                 implementation is [Container](./Container.html)
  #                 If overriding, you must set container on server as well.
  #
  constructor : (args)->
    # make sure this constructor cannot be called a second time 
    # on clientside e.g. from browser console 
    if constructed
      throw new Error("Client already constructed")
    else
      constructed = true

    for k in ['name', 'map', 'models']      
      unless (k of args)
        error = new Error("Client missing required argument: #{k}")
        throw error

    @_name   = args.name
    map      = args.map
    @_models = args.models

    Message.setModels(@_models)

    @_pubsub = new EventEmitter()

    # can override the default container when creating client
    @_container = if ('container' of args)
      args.container
    else
      new Container(
        map    : map
        models : @_models
      )

    # reconnect arg can be object or false. If its an object, set 
    # the associated key value pairs, if its false disable reconnect
    if ('reconnect' of args)
      if (args.reconnect is false)
        @_reconnect.disabled = true
      else
        for k,v of args.reconnect
          @_reconnect[k] = v
    
    # [Mediator](../Mediator.html) provides decoupled pubsub-style
    # communication between client components. We
    Mediator.delegate(
      'send'          : @
      'subscribe'     : @
      'unsubscribe'   : @
      'authenticated' : @
      'user'          : @
      'logout'        : @
      'goto'          : @_container
    )

    # http://caniuse.com/websockets
    if ('WebSocket' of window)
      @_connect()
    else
      # TODO: better handling of this: fall back to $.ajax
      #       and long polling
      @_clientError("WebSockets not supported by browser")
    
    # After document is ready set flag, emit event, and then 
    # init the client.
    $(document).ready(()=>
      @_dom_ready = true
      Mediator.emit('client:domready')
      @_init()
    )

  platform : ()->
    _is = (ua)->
      (navigator.userAgent.indexOf(ua) > 0)

    _android = _is('Android')
    _iphone  = _is('iPhone')
    _ipad    = _is('iPad')
    _ipod    = _is('iPod')

    if _android
      'android'
    else if (_iphone or _ipad or _ipod)
      'ios'
    else
      null

  # authenticated
  # -------------
  authenticated : ()->
    !!@_auth()

  # logout
  # ------
  logout : ()->
    @_auth(null)

  # user
  # ----
  user : ()->
    if @authenticated()
      user_data = @_auth().user
      new @_models.User(user_data)
    else
      null

  # _clientError 
  # ------------
  # Emit an error in the client
  #
  # **message** : error message
  _clientError : (message)->
    error = new Error(message)
    Mediator.emit('client:error', error)
  
  # _init
  # -----
  # This method only runs through its full body after two conditions
  # have been met  
  # 1. domready event has fired in browser
  # 2. socket has opened
  _init : ()->
    unless @_dom_ready and @_socket_open
      return

    data = {
      page_key : @_container.pageKey()
      reload   : false
    }

    if @_container.isLoading()
      if @authenticated()
        location = {}
        for k in ['origin', 'pathname', 'search', 'hash']
          location[k] = window.location[k]

        data.reload   = true
        data.location = location
      else     
        console.log('TODO !! # go to signin page')
        null

    if data
      @send(
        message : {
          name : 'initialize'
          data : data
        }
      )


  # _setup
  # ------
  # **init_data** : the initial data received from initializeReply. 
  _setup : (init_data)=>
    @_container.setup(init_data) 
    Mediator.emit('client:ready')

  # _auth
  # ---------
  # Accessor for auth object. If passed one argument it will 
  # set the auth var and check expiration. If auth is null or 
  # expired it will remove it. If not, it will write it to 
  # localStorage
  # If passed no argument it will read from localStorage (if 
  # neccessary) and check expiration. If unexpired will 
  # return the auth object, otherwise null.
  _auth : (auth)->
    key = "#{@_name}:auth"

    # remove the auth key from client and localStorage
    removeAuth = ()=>
      localStorage.removeItem(key)
      @__auth = null

    # check auth expiration, remove auth from local storage
    # if expired
    checkAuth = ()=>
      unless @__auth
        return

      unless @__auth.user
        removeAuth()
        return
        
      expired = (@__auth.expires and (@__auth.expires < Date.now()))
      if expired
        removeAuth()

    if (arguments.length is 1)
      # its a write
      if auth
        # we have auth data, set it and check expiry
        @__auth = auth
        checkAuth()

        # set if not expired
        if @__auth
          raw_auth = JSON.stringify(@__auth)
          localStorage.setItem(key, raw_auth)
      
      else
        # if single argument is null/falselike remove auth (logout)
        removeAuth()

    else 
      # its a read
      unless @__auth
        raw_auth = localStorage.getItem(key)
        if raw_auth
          @__auth = JSON.parse(raw_auth)

      checkAuth()

      @__auth

  # *WebSocket Methods*
  # -------------------

  # send
  # ----
  # send a message to the server
  #
  # **message** : the message to send
  send: (args) =>
    message  = args.message
    callback = args.callback

    if Type(message, String)
      message = {
        name : message
      }

    unless Type(message, Message)
      message = new Message(message)

    # add the auth token if present
    auth = @_auth()
    message.token = if auth then auth.token else null
    
    raw_message = message.stringify()
    Mediator.emit('client:send', raw_message)
    @_socket.send(raw_message)

    if callback 
      reply_evt = message.replyEventName()
      Mediator.once(reply_evt, callback)

  # subscribe 
  # -------
  # Register a callback for when a publish message
  # is received from the server about a topic
  subscribe : (args)=>
    topic    = args.topic
    callback = args.callback

    @send(
      message : {
        name : 'subscribe'
        data : {
          topic : topic
        }
      }    
    )
    @_pubsub.on(topic, callback)

  # unsubscribe
  # -----------
  # Unregister a callback for a publish message topic
  unsubscribe : (args)=>
    topic    = args.topic
    callback = args.callback

    @send(
      message : {
        name : 'unsubscribe'
        data : {
          topic : topic
        }
      }    
    )
    @_pubsub.removeListener(topic, callback)

  # _connect
  # --------
  # called to connect to server when the Client is 
  # initially constructed and called to reconnect 
  # after the client loses connectivity
  _connect : ()=>
    socket_url = "ws://#{window.location.host}"
    @_socket = new WebSocket(socket_url)
    
    @_socket.onopen    = @_onOpen
    @_socket.onmessage = @_onMessage
    @_socket.onclose   = @_onClose
    @_socket.onerror   = @_onError

    event = if @_reconnect.working
      'reconnecting'
    else
      'connecting'

    Mediator.emit("client:#{event}")
  
  # _onOpen
  # -------
  # callback for when the socket is opened 
  _onOpen : ()=>
    event = if @_reconnect.working
      @_reconnect.attempts = 0
      @_reconnect.working = false
      'reconnected'
    else
      @_socket_open = true
      @_init()
      'connected'
    
    Mediator.emit('client:open')
    Mediator.emit("client:#{event}")

  # _onMessage
  # ----------
  # callback for when a message is received
  _onMessage : (event)=>
    raw_message = event.data
    Mediator.emit('client:receive', raw_message)

    message = Message.parse(raw_message)

    if message.in(['initializeReply', 'authenticateReply', 'publish'])
      @["_onMessage_#{message.name}"](message)

    message_event         = 'message'
    message_event_name    = "#{message_event}:#{message.name}"
    message_event_name_id = "#{message_event_name}:id:#{message.id}"

    Mediator.emit(message_event, message)
    Mediator.emit(message_event_name, message)
    Mediator.emit(message_event_name_id, message)

  # _onMessage_initializeReply
  # ----------------
  _onMessage_initializeReply : (message)->
    if message.isError()
      # TODO: This should show error page
      console.log("TODO !! ERROR IN INITIALIZE.")
      console.log(message.error)
    else
      @_setup(message.data)

  # _onMessage_authenticateReply
  # ------------------
  _onMessage_authenticateReply : (message)->
    data = message.data
    Mediator.emit("client:authenticated", data)
    @_auth(data)

  # _onMessage_publish
  # ------------------
  _onMessage_publish : (message)->
    data       = message.data
    topic      = data.topic
    topic_data = data.data
    @_pubsub.emit(topic, topic_data)

  # _onError
  # --------
  _onError : (error)=>
    console.error(error)
    @_clientError("Socket error")

  # _onClose
  # --------
  # Callback for when client's socket connection to the
  # server closes
  _onClose : ()=>
    Mediator.emit('client:close')

    unless @_reconnect.disabled
      delay = @_reconnectDelay()
      @_reconnect.attempts += 1
      setTimeout(@_connect, delay)
  
  # _reconnectDelay
  # ---------------
  # Calculate delay time before reconnect using exponential backoff 
  # algorithm so that reconnection attempts by different users are 
  # spread out in time rather than all at once
  # 
  # http://dthain.blogspot.com/2009/02/exponential-backoff-in-distributed.html
  #
  # delay = MIN( R * T * F ^ N , M )
  #
  # R should be a random number in the range [1-2], so that its 
  #   effect is to spread out the load over time, but always more 
  #   conservative than plain backoff.
  #
  # T is the initial timeout, and should be set at the outer limits of 
  #   expected response time for the service. For example, if your 
  #   service responds in 1ms on average but in 10ms for 99% of requests, 
  #   then set t=10ms.
  #
  # F doesn't matter much, so choose 2 as a nice round number. 
  #   (It's the exponential nature that counts.)
  #
  # M should be as low as possible to keep your customers happy, 
  #   but high enough that the system can definitely handle requests 
  #   from all clients at that sustained rate.
  _reconnectDelay : ()=>
    spread       = Math.random() + 1
    min_timeout  = @_reconnect.min_timeout
    base         = 2
    max_timeout  = @_reconnect.max_timeout
    attempts     = @_reconnect.attempts

    timeout = spread * min_timeout * Math.pow(base, attempts)
    Math.min(timeout, max_timeout)

# Set the Mediator on the Client
Client.Mediator = Mediator

module.exports = Client