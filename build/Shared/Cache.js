(function() {
  var Cache;

  Cache = (function() {
    Cache.prototype._data = null;

    function Cache() {
      this._data = {};
    }

    Cache.prototype.get = function(key) {
      key = args.key;
      if (key in this._data) {
        return this._data[key];
      } else {
        return null;
      }
    };

    Cache.prototype.put = function(args) {
      var data, key;
      key = args.key;
      data = args.data;
      return this._data[key] = data;
    };

    Cache.prototype.remove = function(args) {
      var key;
      key = args.key;
      return delete this._data[key];
    };

    return Cache;

  })();

  module.exports = Cache;

}).call(this);
