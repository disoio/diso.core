(function() {
  var ClientModel;

  ClientModel = (function() {
    function ClientModel(data) {
      var k, v;
      for (k in data) {
        v = data[k];
        this[k] = v;
      }
    }

    return ClientModel;

  })();

  module.exports = ClientModel;

}).call(this);
