(function() {
  var $, ClientContainer, Mediator, PageMap, Router, Strings,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $ = require('jquery');

  Router = require('diso.router');

  Mediator = require('../Shared/Mediator');

  PageMap = require('../Shared/PageMap');

  Strings = require('../Shared/Strings');

  ClientContainer = (function() {
    function ClientContainer(args) {
      this._onPopState = __bind(this._onPopState, this);
      this.goto = __bind(this.goto, this);
      this._page_map = new PageMap(args);
      this._initializeHistory();
    }

    ClientContainer.prototype.pageKey = function() {
      return $('body').attr(Strings.PAGE_ATTR_NAME);
    };

    ClientContainer.prototype.sync = function(init_data) {
      var error, id_map, page_data, page_id, page_name, _ref, _syncView;
      id_map = init_data[Strings.ID_MAP];
      page_data = init_data[Strings.PAGE_DATA];
      _ref = this.pageKey().split(':'), page_name = _ref[0], page_id = _ref[1];
      if (!page_name) {
        error = new Error("HTML body is missing " + Strings.PAGE_ATTR_NAME + " attribute");
        return error;
      }
      this._page = this._page_map.sync({
        name: page_name,
        location: window.location,
        data: page_data,
        container: this
      });
      if (!this._page) {
        error = new Error("No page named " + page_name);
        return error;
      }
      _syncView = function(args) {
        var i, id, map, subid, subids, submap, subview, subviews, temp_subid, temp_subids, view, _i, _ref1, _results;
        id = args.id;
        map = args.map;
        view = args.view;
        view.setId(id);
        subids = Object.keys(map);
        subviews = view.subviews();
        temp_subids = Object.keys(subviews);
        if (subids.length !== temp_subids.length) {
          error = new Error("Sync failed: Mismatch between map and view");
          throw error;
        }
        if (subids.length === 0) {
          return;
        }
        _results = [];
        for (i = _i = 0, _ref1 = subids.length - 1; 0 <= _ref1 ? _i <= _ref1 : _i >= _ref1; i = 0 <= _ref1 ? ++_i : --_i) {
          subid = subids[i];
          submap = map[subid];
          temp_subid = temp_subids[i];
          subview = subviews[temp_subid];
          _results.push(_syncView({
            id: subid,
            map: submap,
            view: subview
          }));
        }
        return _results;
      };
      this._page.build();
      _syncView({
        id: page_id,
        map: id_map,
        view: this._page
      });
      return this._page.run();
    };

    ClientContainer.prototype.changePage = function(new_page) {
      this._page.remove();
      this._page = new_page;
      $('body').replaceWith(this._page.html());
      this._page.run();
      return this._pushHistory(new_page.route.path());
    };

    ClientContainer.prototype.goto = function(args) {
      var clientError, error, new_page, route;
      route = args.route;
      clientError = function(error) {
        return Mediator.emit('client:error', error);
      };
      new_page = this._page_map.route({
        route: route,
        location: window.location,
        container: this
      });
      if (!new_page) {
        error = new Error("No page for " + route.name);
        return clientError(error);
      }
      if (!this._supportsHistory()) {
        window.location = new_page.route.path();
        return;
      }
      return new_page.load((function(_this) {
        return function(error, data) {
          if (error) {
            return clientError(error);
          }
          new_page.setData(data);
          new_page.build();
          return _this.changePage(new_page);
        };
      })(this));
    };

    ClientContainer.prototype._initializeHistory = function() {
      if (this._supportsHistory()) {
        return $(window).on('popstate', this._onPopState);
      }
    };

    ClientContainer.prototype._supportsHistory = function() {
      var _ref;
      return !!((_ref = window.history) != null ? _ref.pushState : void 0);
    };

    ClientContainer.prototype._onPopState = function() {
      return console.log("HANDLE POP STATE YO:" + document.location);
    };

    ClientContainer.prototype._pushHistory = function(url) {
      return window.history.pushState(null, null, url);
    };

    return ClientContainer;

  })();

  module.exports = ClientContainer;

}).call(this);
