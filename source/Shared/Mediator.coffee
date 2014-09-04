# Core dependencies
# -----------------
# [EventEmitter](http://nodejs.org/api/events.html#events_class_events_eventemitter)  
{EventEmitter} = require('events')

# NPM dependencies
# ------------------
# [type-of-is](https://github.com/stephenhandley/type-of-is)  
Type = require('type-of-is')

# Mediator
# ========
class Mediator extends EventEmitter

  # delegate
  # --------
  # create delegate methods on Mediator to other objects
  delegate : (map)->
    for method,target of map
      do (method, target)=>
        @[method] = ()->
          target[method].apply(target, arguments)
    
module.exports = new Mediator()