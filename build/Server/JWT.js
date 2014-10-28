(function() {
  var JWT, JWTSimple, TOKEN, Type, Url;

  Url = require('url');

  Type = require('type-of-is');

  JWTSimple = require('jwt-simple');

  TOKEN = {
    Expires: 'exp',
    Issuer: 'iss'
  };

  JWT = (function() {
    function JWT(args) {
      this._secret = args.secret;
      this._models = args.models;
    }

    JWT.prototype.encode = function(user) {
      var body, expires, token;
      body = {};
      body[TOKEN.Issuer] = user.id();
      expires = Type(user.tokenExpires, Function) ? user.tokenExpires() : null;
      if (expires) {
        body[TOKEN.Expires] = expires;
      }
      token = JWTSimple.encode(body, this._secret);
      return {
        token: token,
        expires: expires,
        user: user
      };
    };

    JWT.prototype.decode = function(token) {
      var body, expired, expires, now;
      body = JWTSimple.decode(token, this._secret);
      expires = body[TOKEN.Expires];
      expired = expires ? (now = Date.now(), expires < now) : false;
      if (expired) {
        return null;
      } else {
        return body[TOKEN.Issuer];
      }
    };

    JWT.prototype.handle = function(request, response, next) {
      var query, token;
      query = Url.parse(request.url, true).query;
      if (!('token' in query)) {
        return next();
      }
      token = query.token;
      request.token = token;
      return this._decodeTokenAndAddUser({
        token: token,
        target: request,
        callback: next
      });
    };

    JWT.prototype.handleMessage = function(args) {
      var callback, message, token;
      message = args.message;
      callback = args.callback;
      token = message.token;
      if (!token) {
        return callback(null);
      }
      return this._decodeTokenAndAddUser({
        token: token,
        target: message,
        callback: callback
      });
    };

    JWT.prototype._decodeTokenAndAddUser = function(args) {
      var User, callback, has_finder, target, token, user_id;
      token = args.token;
      target = args.target;
      callback = args.callback;
      target.user = null;
      user_id = this.decode(token);
      if (!user_id) {
        return callback();
      }
      target.user_id = user_id;
      User = this._models.User;
      has_finder = User && Type(User.findForJwt, Function);
      if (!has_finder) {
        return callback();
      }
      return User.findForJwt({
        token: token,
        id: user_id,
        callback: function(error, user) {
          if ((!error) && user) {
            target.user = user;
          }
          return callback(error);
        }
      });
    };

    return JWT;

  })();

  module.exports = JWT;

}).call(this);
