# Core dependencies
# -----------------
# [EventEmitter](http://nodejs.org/api/events.html#events_class_events_eventemitter) 
{EventEmitter} = require('events')

# NPM Dependencies
# ----------------
Type = require('type-of-is')

# Local dependencies
# ------------------ 
# [Mediator](./Mediator.html)  
# [Message](./Message.html)  
# [Cache](./Cache.html)  
Mediator = require('../Shared/Mediator')
Message  = require('../Shared/Message')
Cache    = require('../Shared/Cache')

_cache = new Cache()
_events = new EventEmitter

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
_event = (key)->
  "update:#{key}"

# _setData
# --------
_setData = (args)->
  {obj, data} = args
  for k,v of data
    obj[k] = v

# ClientModel
# ===========
# Base class for simple client-side models. Models are generally
# simple wrappers layering a few view assistance methods / logic 
# over the underlying json
class ClientModel
  # constructor
  # -----------
  # **data** : data for this model
  constructor : (data)->
    _setData(
      obj  : @
      data : data
    )

  # @get
  # ---
  # Get data via message to server
  # 
  # **message** : the message to use on a cache miss
  #
  # **callback** : returns (error, data)
  #
  # *cache* : the cache key args (type, id) or (key) to be used for
  #           caching
  @get : (args)->
    message    = args.message
    callback   = args.callback
    cache_args = args.cache

    # first try the cache
    key = if cache_args
      _key(cache_args)
    else
      null

    if key
      data = _cache.get(key : key)
      if data
        return callback(null, data)

    unless Type(message, Message)
      message = new Message(message)
    
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
            _cache.put(
              key  : key
              data : data
            )
            event = @_event(key)
            _events.emit(event, data)

          callback(null, data)

    )

  # @find
  # -----
  # adapter to find model by _id
  @find : (args)->
    _id      = args._id
    callback = args.callback

    @get(
      message : {
        name : 'find'
        data : {
          model : @name 
          _id   : _id
        }
      }
      callback : (error, data)=>
        if error
          callback(error, null)
        else
          callback(null, data.model)
    )

  # @subscribe
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
  @subscribe : (args)->
    callback = args.callback
    key      = _key(args)
    event    = _event(key)
    _events.on(event, callback)

  # @unsubscribe
  # ------------
  # Unsubscribe from updates on objects in store
  #
  # **callback** : callback to unsubscribe
  # 
  # Key can be created from 
  # **type** : constructor type  
  # *id*     : optional object id, otherwise key for full collection  
  # or specified directly
  # **key**  : key 
  @unsubscribe : (args)->
    callback = args.callback
    key      = _key(args)
    event    = _event(key)
    _events.removeListener(event, args.callback)

  # @mixin
  # ------
  # use dotmix mixins 
  # https://github.com/stephenhandley/dotmix
  @mixin : (mixins)->
    unless Type(mixins, Array)
      mixins = [mixins]

    for mixin in mixins
      mixin.mix(into : @)
  
  # setData
  # -------
  # **data** : data to set for this model
  setData : (data)->
    _setData(
      obj  : @
      data : data
    )

module.exports = ClientModel

  
# Mediator.on('message:invalidateCache', @_invalidateCache)

# # _invalidateCache
# # ----------------
# # TODO: Endpoint for server-triggered cache invalidation
# _invalidateCache : (message)->
#   for cache_args in message.data.remove
#     @_cache.remove(cache_args)

