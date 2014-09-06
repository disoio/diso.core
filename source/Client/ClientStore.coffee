# Core dependencies
# -----------------
# [EventEmitter](http://nodejs.org/api/events.html#events_class_events_eventemitter) 
{EventEmitter} = require('events')

# Local dependencies
# ------------------ 
# [Mediator](../Shared/Mediator.html)  
# [Message](../Shared/Message.html)  
Mediator = require('../Shared/Mediator')
Message  = require('../Shared/Message')

# Cache
# =====
class Cache
  # constructor
  # -----------
  # **_store** : backing store for this cache
  constructor : (@_store)->

  # cache!
  _data : {}

  # _key
  # ----
  # Create cache key from type and id
  # 
  # **type** : constructor type
  # **id** : object id
  _key : (args)->
    "#{args.type}:#{args.id}"

  # get
  # ---
  # 
  # **type** : constructor type
  # **id** : object id
  get  : (args)->
    key = @_key(args)

    if key of @_data
      @_data[key]
    else
      null

  # put
  # ---
  # 
  # **type** : constructor type
  # **id** : object id
  put  : (args)->
    key = @_key(args)
    data = args.data

    @_data[key] = data
    @_store.emit(key, data)

  # remove
  # ------
  # 
  # **type** : constructor type
  # **id** : object id
  remove : (args)->
    key = @_key(args)
    delete @_data[key]

# ClientStore
# ===========
# The store used by pages in the client to fetch the data 
# they need. It sends messages over the client's web socket
# and subscribes to their responses, sending that response
# data to the page via callback once it has been received
class ClientStore extends EventEmitter
  # constructor
  # -----------
  constructor : (args)->
    @_cache = new Cache(@)
    
    Mediator.on('message:cache:invalidate', @_invalidateCache)

  # _invalidateCache
  # ----------------
  # TODO: Endpoint for server-triggered cache invalidation
  _invalidateCache : (message)->
    for cache_args in message.data.remove
      @_cache.remove(cache_args)

  # get
  # ---
  # Get data from the store
  # 
  # **message** : the message to use on a cache miss
  #
  # **callback** : returns (error, data)
  #
  # *cache* : the cache key args (type, id) to be used for
  #           caching
  get : (args)->
    message    = args.message
    callback   = args.callback
    cache_args = args.cache

    unless Type(message, Message)
      message = new Message(message)

    # first try the cache
    if cache_args
      data = @_cache.get(cache_args)
      if data
        return callback(null, data)
    
    # cache miss, send message to server
    Mediator.send(message)

    # subscribe to the message reply, and trigger
    # cache update and callback once recieved
    reply_evt = message.replyEventName()
    Mediator.once(reply_evt, (message)=>
      if message.isError()
        callback(message.error)
      else
        data = message.data

        # update cache
        if cache_args
          cache_args.data = data
          @_cache.put(cache_args)

        callback(null, data)
    )

  # subscribe
  # ---------
  # TODO: let page subscribe to updates on objects in cache
  subscribe : (args)->
    key = @_key(args)
    @on("store:update:#{key}", args.callback)

  # unsubscribe
  # -----------
  # TODO: let page unsubscribe from updates on objects in cache
  unsubscribe : (args)->
    key = @_key(args)
    @removeListener("store:update:#{key}", args.callback)

module.exports = ClientStore