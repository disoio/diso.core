# ClientModel
# ===========
# Base class for simple client-side models. Models are generally
# simple wrappers layering methods / logic over the underlying json
class ClientModel
  # constructor
  # -----------
  # ### required args
  # **data** : data for this model
  constructor : (data)->
    for k,v of data
      @[k] = v

module.exports = ClientModel