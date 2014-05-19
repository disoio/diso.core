{EventEmitter} = require('events')

class Mediator extends EventEmitter
  client : null
  
  # the client sets itself as an instance variable on Mediator in 
  # its constructor... this is a safety check in case that doesn't
  # happen for some reason 
  ensureClient : ()->
    unless @client
      throw "Mediator has no client"

  ensureRouter : ()->
    unless @router
      throw "Mediator has no router"
   
  send : (message)->
    @ensureClient()
    @client.send(message)

  formatRoute : (options)->
    @ensureRouter()
    @router.format(options)
    
  swapBody : (options)->
    @ensureClient()
    @client.swapBody(options)
    
module.exports = new Mediator()