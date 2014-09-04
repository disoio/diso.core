{EventEmitter}   = require('events')

Mediator = require('../Shared/Mediator')
Message  = require('../Shared/Message')

class Cache 
  constructor : (@_store)->

  _data : {}

  _key : (args)->
    "#{args.type}:#{args.id}"

  get  : (args)->
    key = @_key(args)

    if key of @_data
      @_data[key]
    else
      null

  put  : (args)->
    key = @_key(args)
    data = args.data

    @_data[key] = data
    @_store.emit(key, data)

  remove : (args)->
    key = @_key(args)
    delete @_data[key]

class ClientStore extends EventEmitter
  constructor : (args)->
    @_cache = new Cache(@)
    
    Mediator.on('message:cache:invalidate', @_invalidateCache)

  _invalidateCache : (message)->
    for cache_args in message.data.remove
      @_cache.remove(cache_args)

  get : (args)->
    message    = args.message
    callback   = args.callback
    cache_args = args.cache

    unless Type(message, Message)
      message = new Message(message)

    if cache_args
      data = @_cache.get(cache_args)
      if data
        return callback(null, data)
   
    Mediator.send(message)

    reply_evt = message.replyEventName()
    Mediator.once(reply_evt, (message)=>
      if message.error 
        callback(message.error)
      else
        data = message.data

        if cache_args
          cache_args.data = data
          @_cache.put(cache_args)

        callback(null, data)
    )

  subscribe : (args)->
    key = @_key(args)
    @on(key, args.callback)

  unsubscribe : (args)->
    key = @_key(args)
    @removeListener(key, args.callback)

module.exports = ClientStore