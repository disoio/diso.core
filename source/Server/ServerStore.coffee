class ServerStore
  constructor : (@_messages)->

  get : (args)->
    message    = args.message
    callback   = args.callback

    handler = @_messages[message.name]

    if handler
      handler(
        message  : message
        callback : callback
      )
    else
      error = "Message:#{message.name} is not supported"
      console.error(error)
      callback(error)


module.exports = ServerStore