# ServerStore
# ===========
# The store used by pages on the server to fetch the data
# they need for rendering. Basically just delegates to the 
# user-provided messages object to handle the message

class ServerStore
  # constructor
  # -----------
  # **_messages** : object with message handlers
  constructor : (@_messages)->

  # get
  # ---
  # **message** : message to fetch data
  # 
  # **callback** : returns data for message
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
      error = new Error("Message:#{message.name} is not supported")
      console.error(error)
      callback(error)


module.exports = ServerStore