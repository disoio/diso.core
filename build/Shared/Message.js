(function() {
  var MODEL_KEY, Message, ShortId, Type, deflate, inflate, models,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  ShortId = require('shortid');

  Type = require('type-of-is');

  MODEL_KEY = '$model';

  models = null;

  deflate = function(obj) {
    var k, res, v;
    switch (Type(obj)) {
      case Array:
        return obj.map(deflate);
      case Object:
        res = {};
        for (k in obj) {
          v = obj[k];
          res[k] = deflate(v);
        }
        return res;
      default:
        if (obj && obj.deflate && Type(obj.deflate, Function)) {
          return obj.deflate({
            model_key: MODEL_KEY
          });
        } else {
          return obj;
        }
    }
  };

  inflate = function(obj) {
    var Model, k, model_name, res, v;
    if (!models) {
      return obj;
    }
    switch (Type(obj)) {
      case Array:
        return obj.map(inflate);
      case Object:
        res = {};
        Model = null;
        if (MODEL_KEY in obj) {
          model_name = obj[MODEL_KEY];
          delete obj[MODEL_KEY];
          Model = model_name in models ? models[model_name] : (console.error("Can't find Model for " + model_name), null);
        }
        for (k in obj) {
          v = obj[k];
          res[k] = inflate(v);
        }
        if (Model) {
          res = new Model(res);
        }
        return res;
      default:
        return obj;
    }
  };

  Message = (function() {
    Message.prototype.name = null;

    Message.prototype.id = null;

    Message.prototype.token = null;

    Message.prototype.data = null;

    Message.prototype.error = null;

    function Message(args) {
      if (!args.name) {
        throw new Error("Message must have name");
      }
      this.name = args.name;
      this.id = args.id || ShortId.generate();
      this.token = args.token;
      this.data = 'data' in args ? inflate(args.data) : {};
      this.error = null;
      if (args.error) {
        this.error = args.error;
        if (!Type(this.error, Error)) {
          this.error = new Error(this.error);
        }
      }
    }

    Message.setModels = function(_models) {
      return models = _models;
    };

    Message.parse = function(json) {
      var error, message_data;
      try {
        message_data = JSON.parse(json);
      } catch (_error) {
        error = _error;
        return this.error("JSON.parse failed");
      }
      return new this(message_data);
    };

    Message.prototype.reply = function(args) {
      args.name = this.replyName();
      args.id = this.id;
      return new this.constructor(args);
    };

    Message.prototype.replyName = function() {
      return "" + this.name + "Reply";
    };

    Message.prototype.replyEventName = function() {
      return "message:" + (this.replyName()) + ":id:" + this.id;
    };

    Message.prototype.stringify = function() {
      var message;
      message = {
        name: this.name,
        id: this.id,
        token: this.token
      };
      if (this.error) {
        message.error = this.error.message;
      }
      if (this.data) {
        message.data = this.data;
      }
      message = deflate(message);
      return JSON.stringify(message);
    };

    Message.prototype.isError = function() {
      return !!this.error;
    };

    Message.prototype.is = function(name) {
      return this.name === name;
    };

    Message.prototype["in"] = function(names) {
      var _ref;
      return _ref = this.name, __indexOf.call(names, _ref) >= 0;
    };

    return Message;

  })();

  module.exports = Message;

}).call(this);
