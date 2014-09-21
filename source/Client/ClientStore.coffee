# Core dependencies
# -----------------
# [EventEmitter](http://nodejs.org/api/events.html#events_class_events_eventemitter) 
{EventEmitter} = require('events')

# Local dependencies
# ------------------ 
# [Mediator](./Mediator.html)  
# [Message](./Message.html)  
# [Cache](./Cache.html)  
Mediator = require('../Shared/Mediator')
Message  = require('../Shared/Message')
Cache    = require('../Shared/Cache')

# ClientStore
# ===========
# The store used by pages in the client to fetch the data 
# they need. It sends messages over the client's web socket
# and subscribes to their responses, sending that response
# data to the page via callback once it has been received
class ClientStore extends EventEmitter
  # constructor
  # -----------
  constructor : ()->
    @_cache = new Cache()
    
    Mediator.on('message:invalidateCache', @_invalidateCache)

  # _invalidateCache
  # ----------------
  # TODO: Endpoint for server-triggered cache invalidation
  _invalidateCache : (message)->
    for cache_args in message.data.remove
      @_cache.remove(cache_args)


  # key
  # ----
  # Create cache key from type and id or directly from key
  # 
  # Key can be created from 
  # **type** : constructor type  
  # *id*     : optional object id, otherwise key for full collection  
  # or specified directly
  # **key**  : key 
  _key : (args)->
    if ('key' of args)
      args.key
    else
      key = args.type
      if ('id' of args) 
        key = "#{key}:#{args.id}"
      key

  # _event
  # ------
  # Returns the event emit / subscribed to for a given key
  _event : (key)->
    "update:#{key}"

  # get
  # ---
  # Get data from the store
  # 
  # **message** : the message to use on a cache miss
  #
  # **callback** : returns (error, data)
  #
  # *cache* : the cache key args (type, id) or (key) to be used for
  #           caching
  get : (args)->
    message    = args.message
    callback   = args.callback
    cache_args = args.cache

    unless Type(message, Message)
      message = new Message(message)

    # first try the cache
    key = if cache_args
      @_key(cache_args)
    else
      null

    if key
      data = @_cache.get(key : key)
      if data
        return callback(null, data)
    
    # cache miss, send message to server
    # trigger cache update on reply
    Mediator.send(
      message  : message
      callback : (reply)=>
        if reply.isError()
          callback(reply.error, null)
        else
          data = reply.data

          # update cache
          if key
            @_cache.put(
              key  : key
              data : data
            )
            event = @_event(key)
            @emit(event, data)

          callback(null, data)

    )

  # subscribe
  # ---------
  # Subscribe to updates on objects in store
  #
  # **callback** : callback to call on update
  # 
  # Key can be created from 
  # **type** : constructor type  
  # *id*     : optional object id, otherwise key for full collection  
  # or specified directly
  # **key**  : key 
  subscribe : (args)->
    callback = args.callback
    key      = @_key(args)
    event    = @_event(key)
    @on(event, callback)

  # unsubscribe
  # -----------
  # Unsubscribe from updates on objects in store
  #
  # **callback** : callback to unsubscribe
  # 
  # Key can be created from 
  # **type** : constructor type  
  # *id*     : optional object id, otherwise key for full collection  
  # or specified directly
  # **key**  : key 
  unsubscribe : (args)->
    callback = args.callback
    key      = @_key(args)
    event    = @_event(key)
    @removeListener(event, args.callback)

module.exports = ClientStore