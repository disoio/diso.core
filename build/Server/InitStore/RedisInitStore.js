(function() {
  var MemoryInitStore, Redis;

  Redis = require("redis");

  MemoryInitStore = (function() {
    function MemoryInitStore(config) {
      this.client = Redis.createClient(config);
    }

    MemoryInitStore.prototype.set = function(args) {
      var callback, key, value;
      key = args.key, value = args.value, callback = args.callback;
      return this.client.set(key, value, callback);
    };

    MemoryInitStore.prototype.get = function(args) {
      var callback, key;
      key = args.key, callback = args.callback;
      return this.client.get(key, function(error, value) {
        if (!error) {
          this.client.del(key);
        }
        return callback(error, value);
      });
    };

    return MemoryInitStore;

  })();

  module.exports = MemoryInitStore;

}).call(this);
