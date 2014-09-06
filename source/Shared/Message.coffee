# NPM dependencies
# ------------------
# [shortid](https://github.com/dylang/shortid)  
# [type-of-is](https://github.com/stephenhandley/type-of-is)  
ShortId = require('shortid')
Type = require('type-of-is')

# attribute name used for serializing a model's type with its
# data via deflate
MODEL_KEY = '$model'

# object mapping from model names to constructors that 
# needs to be set via Message.setModels
models = null

# deflate
# -------
# Deflate the passed object so that it can be passed over the
# wire as json and inflated on the other end into models
# 
# **obj** : object to deflate
deflate = (obj)->
  switch Type(obj)
    when Array
      obj.map(deflate)

    when Object
      res = {}
      for k,v of obj
        res[k] = deflate(v) 
      res

    else
      if (obj and obj.deflate and Type(obj.deflate, Function))
        obj.deflate(
          model_key : MODEL_KEY
        )
      else
        obj

# inflate 
# --------
# Inflate the passed json object by converting plain json objects
# into instances of their associated model. Model types are specified
# via model key defined in [Strings](./String.html)
#
# **obj** : object to inflate
inflate = (obj)->
  unless models
    return obj

  switch Type(obj)
    # map over arrays
    when Array
      obj.map(inflate)

    # traverse object and inflate its values
    when Object
      res = {} 

      Model = null

      # if there is a MODEL_KEY attribute present in the json, use
      # it to lookup the associated model
      if (MODEL_KEY of obj)
        model_name = obj[MODEL_KEY]
        delete obj[MODEL_KEY]

        Model = if (model_name of models)
          models[model_name]
        else
          console.error("Can't find Model for #{model_name}")
          null
          
      for k,v of obj
        res[k] = inflate(v)

      if Model
        res = new Model(res)

      res

    # return everything else as is
    else 
      obj

# Message
# =======
# A WebSocket message
class Message
  # name for this message
  name  : null

  # unique id for this message (shared by its reply)
  id    : null

  # jwt auth token
  token : null

  # the data for this message
  data  : null

  # an error if needed
  error : null

  # constructor
  # -----------
  # Create a message
  #
  # ### required args
  # **name** : the name for this message
  # 
  # *id*     : id for this message, otherwise will be generated
  #
  # *token*  : jwt token used to identify / authorize the user
  #            sending this message
  #
  # *data*   : the data / params for this message
  #
  # *error*  : used in replies if error occured during processing
  #            of message
  constructor : (args)->
    unless args.name
      throw new Error("Message must have name")

    @name  = args.name
    @id    = args.id || ShortId.generate()
    @token = args.token
    @data  = inflate(args.data || {})

    @error = if ('error' of args)
      error = args.error
      unless Type(error, Error)
        error = new Error(error) 
      error        
    else 
      null

  # @setModels
  # ----------
  # Set the models to be used by inflate
  #
  # **_models** : models to be used for inflation
  @setModels : (_models)->
    models = _models

  # @parse
  # ------
  # Parse and create message from raw josn string
  #
  # **json** : the raw json to parse
  @parse : (json)->
    try 
      message_data = JSON.parse(json)
    catch error
      return @error("JSON.parse failed")

    new @(message_data)

  # reply
  # ------
  # Create a reply message from this message using its id
  # 
  # *data* : data for the reply
  #
  # *error* : error
  reply : (args)->
    args.name = @replyName()
    args.id   = @id
    new @constructor(args)

  # replyName
  # ---------
  # The name of the reply to this message
  replyName : ()->
    "#{@name}Reply"

  # replyEventName
  # --------------
  # The event name that gets triggered by this message's reply
  # This is used in the [ClientStore](../Client/ClientStore.html)
  # in order to trigger load callback once the data is available
  replyEventName : ()->
    "message:#{@replyName()}:id:#{@id}"

  # stringify
  # ---------
  # Encode this message into json, deflating its data in the process
  stringify : ()->
    message = {
      name  : @name
      id    : @id
      token : @token
    }

    if @error 
      message.error = @error
    
    if @data
      message.data = @data
    
    message = deflate(message)
    JSON.stringify(message)

  # isError
  # -------
  # Returns true if this message has an error
  isError : ()->
    !!@error

  # is
  # --
  # Convenience method for checking the name of this message
  # 
  # **name** : message name to check against
  is : (name)->
    (@name is name)
  
  # in
  # --
  # Convenience method for checking whether this message's is one
  # of several possibilities
  #
  # **names** : message names to check against
  in : (names)->
    (@name in names)

module.exports = Message