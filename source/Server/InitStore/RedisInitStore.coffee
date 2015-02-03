Redis = require("redis")

class MemoryInitStore 
  constructor : (config)->
    @client = Redis.createClient(config)

  set : (args)->
    {key, value, callback} = args
    @client.set(key, value, callback)

  get : (args)->
    {key, callback} = args
    @client.get(key, (error, value)->
      unless error 
        @client.del(key)
      callback(error, value)
    )

module.exports = MemoryInitStore