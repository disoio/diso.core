{EventEmitter} = require('events')
Type           = require('type-of-is')

# TODO : local storage?
cache = {}

class Mediator extends EventEmitter
  client : null

  setup : (opts)->
    @client = opts.client
    @models = opts.models
    @router = opts.router
   
  send : (message)->
    @client.send(message)

  formatRoute : (route)->
    @router.format(route)
    
  loadBody : (options)->
    @client.loadBody(options)

  pushView : (opts)->
    @client.page.swapBody(opts.view)
    url = @formatRoute(opts.route)
    @client.navigate(url)

  cache : (k, v)->
    if v
      cache[k] = v
    else if k of cache
      cache[k]
    else
      throw new Error("#{k} not found in client cache") 

    
module.exports = new Mediator()