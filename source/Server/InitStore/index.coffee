STORES = {
  memory : require('./MemoryInitStore')
  redis  : require('./RedisInitStore')
}

create = (config)->
  type = config.type
  delete config.type

  Store = STORES[type]

  if Store
    new Store(config)
  else
    throw new Error("Unsupported init store : #{type}")

module.exports = {
  create : create
}