(function() {
  var ServerModel, Type,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Type = require('type-of-is');

  ServerModel = (function() {
    ServerModel.mixin = function(mixins) {
      var mixin, _i, _len, _results;
      if (!Type(mixins, Array)) {
        mixins = [mixins];
      }
      _results = [];
      for (_i = 0, _len = mixins.length; _i < _len; _i++) {
        mixin = mixins[_i];
        _results.push(mixin.mix({
          into: this
        }));
      }
      return _results;
    };

    ServerModel.attrs = function(attrs) {
      var attr, _i, _len, _results;
      if (!attrs) {
        return this._attrs;
      }
      this._attrs = attrs;
      _results = [];
      for (_i = 0, _len = attrs.length; _i < _len; _i++) {
        attr = attrs[_i];
        _results.push((function(_this) {
          return function(attr) {
            if (!(attr in _this.prototype)) {
              return Object.defineProperty(_this.prototype, attr, {
                get: function() {
                  return this._data[attr];
                },
                set: function(val) {
                  return this._data[attr] = val;
                }
              });
            }
          };
        })(this)(attr));
      }
      return _results;
    };

    function ServerModel(data) {
      var k, v;
      if (!this.constructor._attrs) {
        throw new Error("Model " + this.constructor.name + " muse have attrs defined.");
      }
      this._data = {};
      for (k in data) {
        v = data[k];
        if (__indexOf.call(this.constructor._attrs, k) >= 0) {
          this._data[k] = v;
        }
      }
    }

    ServerModel.prototype.deflate = function(args) {
      var attrs, data, k, model_key, v, _data;
      model_key = args.model_key, attrs = args.attrs;
      data = (function() {
        var _ref;
        if (attrs) {
          _data = {};
          _ref = this._data;
          for (k in _ref) {
            v = _ref[k];
            if (__indexOf.call(attrs, k) >= 0) {
              _data[k] = v;
            }
          }
          return _data;
        } else {
          return this._data;
        }
      }).call(this);
      data[model_key] = this.constructor.name;
      return data;
    };

    return ServerModel;

  })();

  module.exports = ServerModel;

}).call(this);
