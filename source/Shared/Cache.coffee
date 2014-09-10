# Cache
# =====
class Cache
  # teh data
  _data : null

  constructor : ()->
    # TODO: read from localStorage
    @_data = {}

  # get
  # ---
  # Get data from cache
  #
  # **key** : key to get
  get : (key)->
    key = args.key

    if key of @_data
      @_data[key]
    else
      null

  # put
  # ---
  # Put data into the cache
  #
  # **key** : key to put
  #
  # **data** : data to put
  put : (args)->
    key  = args.key
    data = args.data
    @_data[key] = data

  # remove
  # ------
  # Remove data from the cache
  #
  # **key** : key to remove
  remove : (args)->
    key = args.key
    delete @_data[key]

module.exports = Cache