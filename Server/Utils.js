(function() {
  var Utils;

  Utils = {
    parseAcceptHeader: function(str) {
      var index;
      index = 0;
      return str.split(/,\s+/).map(function(accept_str) {
        var name, param, params, parts, subtype, type, val, _i, _len, _ref, _ref1;
        parts = accept_str.split(/;\s+/);
        _ref = parts.shift().split('/'), type = _ref[0], subtype = _ref[1];
        params = {
          q: 1.0
        };
        for (_i = 0, _len = parts.length; _i < _len; _i++) {
          param = parts[_i];
          _ref1 = param.split('='), name = _ref1[0], val = _ref1[1];
          if (name === 'q') {
            val = parseFloat(val);
          }
          params[name] = val;
        }
        return {
          index: index++,
          type: type,
          subtype: subtype,
          params: params
        };
      }).sort(function(a, b) {
        if (a.params.q === b.params.q) {
          return a.index - b.index;
        } else {
          return b.params.q - a.params.q;
        }
      });
    }
  };

  module.exports = Utils;

}).call(this);
