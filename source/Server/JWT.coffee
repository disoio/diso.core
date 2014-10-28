# Core dependencies
# -----------------
# [url](http://nodejs.org/api/url.html)
Url = require('url')

# NPM dependencies
# ----------------
# [type-of-is](https://github.com/stephenhandley/type-of-is)  
# [jsonwebtoken](https://github.com/auth0/node-jsonwebtoken)  
Type      = require('type-of-is')
JWTSimple = require('jwt-simple')

# token attributes used by JWT
TOKEN = {
  Expires : 'exp'
  Issuer  : 'iss'
}

# JWT
# ===
# Json Web Token processor for messages that functions in
# both SocketHandler and as Connect middleware that finds
# user for incoming message/request by decoding JWT and 
# retrieving user via model lookup on token issuer (user_id)
class JWT

  # constructor
  # -----------
  # **secret** : secret used for JWT encode/decode
  #
  # **models** : server side models used for retrieving a
  #              a User model for lookup
  constructor : (args)->
    @_secret = args.secret
    @_models = args.models

  # encode
  # ------
  # Creates a JWT token from user model
  #
  # **user** : the user instance to encode token for
  encode : (user)->
    body = {}
    body[TOKEN.Issuer] = user.id()
    
    expires = if Type(user.tokenExpires, Function)
      user.tokenExpires()
    else
      null

    if expires
      body[TOKEN.Expires] = expires

    token = JWTSimple.encode(body, @_secret)

    {
      token   : token
      expires : expires
      user    : user
    }

  # decode
  # ------
  # Decodes a token and returns issuer i.e. user_id
  #
  # **token** : token to decode
  decode : (token)->
    body = JWTSimple.decode(token, @_secret)

    # check token expiration
    expires = body[TOKEN.Expires]
    expired = if expires
      now = Date.now()
      (expires < now)
    else
      false

    if expired
      null
    else
      body[TOKEN.Issuer]

  # handle
  # ------
  # Connect middleware hook for processing an incoming http request
  # looking for token and augmenting request with user attribute
  # if decode and lookup are successful
  #
  # **request,response,next**: the standard connect middleware trio
  handle : (request, response, next)->
    query = Url.parse(request.url, true).query
    
    unless ('token' of query)
      return next()

    token = query.token

    request.token = token

    @_decodeTokenAndAddUser(
      token    : token
      target   : request
      callback : next
    )

  # handleMessage
  # -------------
  # Processes a websocket message's token and augment message with user
  # attribute if decode and lookup are successful
  #
  # **message** : message to process
  # 
  # **callback** : returns (error) if there is one
  handleMessage : (args)->
    message  = args.message
    callback = args.callback

    token = message.token

    unless token
      return callback(null)

    @_decodeTokenAndAddUser(
      token    : token
      target   : message
      callback : callback
    )

  # _decodeTokenAndAddUser
  # ----------------------
  # Helper method that decodes a token and finds a user 
  # for the token's user_id
  # 
  # **token** : token to decode
  # 
  # **target** : the target to augment with a user attribute
  # 
  # **callback** : returns (error) if there is one
  _decodeTokenAndAddUser : (args)->
    token    = args.token
    target   = args.target
    callback = args.callback

    target.user = null

    user_id = @decode(token)

    unless user_id
      return callback()

    target.user_id = user_id

    User = @_models.User
    has_finder = (User and Type(User.findForJwt, Function))

    unless has_finder
      return callback()

    User.findForJwt(
      token    : token
      id       : user_id
      callback : (error, user)->
        if ((not error) and user)
          target.user = user
        callback(error)
    )

module.exports = JWT