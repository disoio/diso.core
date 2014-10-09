(function() {
  var ServerContainer, Strings, Tag, Type;

  Tag = require('tf');

  Type = require('type-of-is');

  Strings = require('../Shared/Strings');

  ServerContainer = (function() {
    ServerContainer.prototype._init_page_data = null;

    ServerContainer.prototype._status = 200;

    function ServerContainer(args) {
      this._site_name = args.site_name;
      this._logo_url = args.logo_url;
    }

    ServerContainer.prototype._idMap = function() {
      var idMap;
      idMap = function(view) {
        var id, map, subview, _ref;
        map = {};
        _ref = view.subviews();
        for (id in _ref) {
          subview = _ref[id];
          map[subview.id] = idMap(subview);
        }
        return map;
      };
      return idMap(this._page);
    };

    ServerContainer.prototype.load = function(args) {
      var callback;
      this._page = args.page;
      callback = args.callback;
      return this._page.load((function(_this) {
        return function(error, data) {
          if (!error) {
            _this._page.setData(data);
            _this._page.build();
          }
          return callback(error);
        };
      })(this));
    };

    ServerContainer.prototype.initData = function() {
      var result;
      result = {};
      result[Strings.ID_MAP] = this._idMap();
      result[Strings.PAGE_DATA] = this._page.data;
      return result;
    };

    ServerContainer.prototype.status = function() {
      return this._status;
    };

    ServerContainer.prototype.headers = function() {
      return this._page.headers();
    };

    ServerContainer.prototype.html = function() {
      var href, src;
      return "<!DOCTYPE html>\n<html>\n  <head>\n    " + (this._meta()) + "\n\n    <title>" + (this._title()) + "</title>\n\n    " + (((function() {
        var _i, _len, _ref, _results;
        _ref = this._page.styles;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          href = _ref[_i];
          _results.push(Tag.stylesheet({
            href: href
          }));
        }
        return _results;
      }).call(this)).join("\n")) + "\n    \n    " + (((function() {
        var _i, _len, _ref, _results;
        _ref = this._page.scripts;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          src = _ref[_i];
          _results.push(Tag.script({
            src: src
          }));
        }
        return _results;
      }).call(this)).join("\n")) + "\n    \n    " + (this._page.head()) + "        \n  </head>\n  \n  <body " + (this._pageAttr()) + ">\n    " + (this._page.html()) + "\n  </body>\n</html>";
    };

    ServerContainer.prototype.text = function() {
      return this._page.text();
    };

    ServerContainer.prototype.json = function() {
      return this._page.json();
    };

    ServerContainer.prototype._meta = function() {
      var args, attr, content, html, image, k, m, meta, metadata, name, title, type, url, v, _ref;
      meta = this._page.getMeta();
      url = this._page.url;
      title = this._title();
      image = meta.image || this._logo_url;
      type = meta.type || 'website';
      metadata = {
        name: {
          description: meta.description,
          viewport: this._page.viewport || 'width=device-width, initial-scale=1'
        },
        itemprop: {
          name: title,
          description: meta.description,
          image: image,
          url: url
        },
        property: {
          "og:title": title,
          "og:description": meta.description,
          "og:image": image,
          "og:url": url,
          "og:type": type,
          "og:site_name": this._site_name
        }
      };
      if (meta.og) {
        _ref = meta.og;
        for (k in _ref) {
          v = _ref[k];
          metadata.property["og:" + k] = v;
        }
      }
      html = Tag.meta({
        charset: 'utf-8'
      }) + "\n";
      for (attr in metadata) {
        m = metadata[attr];
        for (name in m) {
          content = m[name];
          args = {
            content: content
          };
          args[attr] = name;
          html += Tag.meta(args) + "\n";
        }
      }
      return html;
    };

    ServerContainer.prototype._title = function() {
      return this._page.title() || this._site_name;
    };

    ServerContainer.prototype._pageAttr = function() {
      return "" + Strings.PAGE_ATTR_NAME + "=\"" + (this._page.key()) + "\"";
    };

    return ServerContainer;

  })();

  module.exports = ServerContainer;

}).call(this);
