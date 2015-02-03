(function() {
  var MemoryInitStore;

  MemoryInitStore = (function() {
    function MemoryInitStore() {
      this._store = {};
    }

    MemoryInitStore.prototype.set = function(args) {
      var callback, key, value;
      key = args.key, value = args.value, callback = args.callback;
      this._store[key] = value;
      return callback(null);
    };

    MemoryInitStore.prototype.get = function(args) {
      var callback, key, value;
      key = args.key, callback = args.callback;
      value = this._store[key];
      delete this._store[key];
      return callback(null, value);
    };

    return MemoryInitStore;

  })();

  module.exports = MemoryInitStore;

}).call(this);
