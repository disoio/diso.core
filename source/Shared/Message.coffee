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
#     
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
class Message
  name  : null
  id    : null
  token : null
  data  : null
  error : null

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
  @setModels : (_models)->
    models = _models

  @error : (error)->
    new @(
      name  : 'error'
      error : error
    )

  @parse : (raw_message)->
    try 
      message_data = JSON.parse(raw_message)
    catch error
      return @error("JSON.parse failed")

    new @(message_data)

  reply : (data)->
    new @constructor(
      name   : @replyName()
      data   : data
      id     : @id
    )

  replyName : ()->
    "#{@name}Reply"

  replyEventName : ()->
    "message:#{@replyName()}:id:#{@id}"

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

  isError : ()->
    !!@error

  is : (name)->
    (@name is name)
  
  in : (names)->
    (@name in names)

module.exports = Message