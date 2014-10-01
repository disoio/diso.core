(function() {
  var ClientModel;

  ClientModel = (function() {
    function ClientModel(data) {
      this.setData(data);
    }

    ClientModel.prototype.setData = function(data) {
      var k, v, _results;
      _results = [];
      for (k in data) {
        v = data[k];
        _results.push(this[k] = v);
      }
      return _results;
    };

    return ClientModel;

  })();

  module.exports = ClientModel;

}).call(this);
