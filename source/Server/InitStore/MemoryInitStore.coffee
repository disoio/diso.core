class MemoryInitStore 
  constructor : ()->
    @_store = {}

  set : (args)->
    {key, value, callback} = args
    @_store[key] = value
    callback(null)

  get : (args)->
    {key, callback} = args
    value = @_store[key]
    delete @_store[key]
    callback(null, value)

module.exports = MemoryInitStore