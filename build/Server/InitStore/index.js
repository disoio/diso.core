(function() {
  var STORES, create;

  STORES = {
    memory: require('./MemoryInitStore'),
    redis: require('./RedisInitStore')
  };

  create = function(config) {
    var Store, type;
    type = config.type;
    delete config.type;
    Store = STORES[type];
    if (Store) {
      return new Store(config);
    } else {
      throw new Error("Unsupported init store : " + type);
    }
  };

  module.exports = {
    create: create
  };

}).call(this);
