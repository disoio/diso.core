Type = require('type-of-is')

# ServerModel
# ===========
# Simple server-side model supporting basic deflate
# for transport and data access
class ServerModel
  # @mixin
  # ------
  # use dotmix mixins 
  # https://github.com/stephenhandley/dotmix
  @mixin : (mixins)->
    unless Type(mixins, Array)
      mixins = [mixins]

    for mixin in mixins
      mixin.mix(into : @)

  # @attrs
  # ------
  # Specifiy attributes in this schema
  @attrs : (attrs)->
    # read
    unless attrs
      return @_attrs

    # write
    @_attrs = attrs

    for attr in attrs
      do (attr)=>
        unless attr of @prototype
          Object.defineProperty(@prototype, attr, {
            get: ()->
              @_data[attr]

            set: (val)->
              @_data[attr] = val
          })

  # constructor
  # -----------
  # **data** : data for this model
  constructor : (data)->
    unless @constructor._attrs 
      throw new Error("Model #{@constructor.name} muse have attrs defined.")

    @_data = {}
    for k,v of data
      if k in @constructor._attrs
        @_data[k] = v

  # deflate
  # -------
  # Called by server to create json object for transfer over
  # the wire
  #
  # ### required args
  # **model_key** : The attribute name used to hold the model's 
  #                 constructor name to be used by inflate
  #
  # ### optional args
  # **attrs** : Only include the specified attributes
  deflate : (args)->
    {model_key, attrs} = args

    data = if attrs
      _data = {}
      for k,v of @_data
        if k in attrs
          _data[k] = v
      _data

    else
      @_data

    data[model_key] = @constructor.name
    data

module.exports = ServerModel