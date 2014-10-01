# ClientModel
# ===========
# Base class for simple client-side models. Models are generally
# simple wrappers layering methods / logic over the underlying json
class ClientModel
  # constructor
  # -----------
  # **data** : data for this model
  constructor : (data)->
    @setData(data)
  
  # setData
  # -------
  # **data** : data to set for this model
  setData : (data)->
    for k,v of data
      @[k] = v

module.exports = ClientModel