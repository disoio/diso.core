(function() {
  var ClientModel, MODEL_KEY;

  MODEL_KEY = '$model';

  ClientModel = (function() {
    function ClientModel(data) {
      var k, v;
      for (k in data) {
        v = data[k];
        this[k] = v;
      }
    }

    ClientModel.models = null;

    ClientModel.inflate = function(obj) {
      var Model, k, model_name, res, v;
      if (!ClientModel.models) {
        throw new Error("Can't inflate object unless ClientModel.models has been set");
      }
      switch (Type(obj)) {
        case Array:
          return obj.map(ClientModel.inflate);
        case Object:
          res = {};
          Model = null;
          if ('$model' in obj) {
            model_name = obj.$model;
            delete obj.$model;
            if (!(model_name in ClientModel.models)) {
              throw new Error("Can't find model for " + model_name);
            }
            Model = ClientModel.models[model_name];
          }
          for (k in obj) {
            v = obj[k];
            res[k] = ClientModel.inflate(v);
          }
          if (Model) {
            res = new Model(res);
          }
          return res;
        default:
          return obj;
      }
    };

    return ClientModel;

  })();

  module.exports = ClientModel;

}).call(this);
