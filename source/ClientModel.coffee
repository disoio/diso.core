MODEL_KEY = '$model'

class ClientModel
  constructor : (data)->
    for k,v of data
      @[k] = v

  @models : null

  @inflate : (obj)=>
    unless @models
      throw new Error("Can't inflate object unless ClientModel.models has been set")

    switch Type(obj)
      when Array
        obj.map(@inflate)

      when Object
        res = {} 

        Model = null
        if ('$model' of obj)
          model_name = obj.$model
          delete obj.$model

          unless (model_name of @models)
            throw new Error("Can't find model for #{model_name}")
          
          Model = @models[model_name]

        for k,v of obj
          res[k] = @inflate(v)

        if Model
          res = new Model(res)

        res

      else 
        obj

module.exports = ClientModel