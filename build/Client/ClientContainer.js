(function() {
  var $, ClientContainer, Mediator, PageMap, Router, Strings,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $ = require('jquery');

  Router = require('diso.router');

  Mediator = require('../Shared/Mediator');

  PageMap = require('../Shared/PageMap');

  Strings = require('../Shared/Strings');

  ClientContainer = (function() {
    ClientContainer.prototype._$body = null;

    function ClientContainer(args) {
      this._onPopState = __bind(this._onPopState, this);
      this.goto = __bind(this.goto, this);
      this._page_map = new PageMap(args);
      this._initializeHistory();
    }

    ClientContainer.prototype.$body = function() {
      if (!this._$body) {
        this._$body = $('body');
      }
      return this._$body;
    };

    ClientContainer.prototype.pageKey = function() {
      return this.$body().attr(Strings.PAGE_ATTR_NAME);
    };

    ClientContainer.prototype.pageId = function() {
      return this.pageKey().split(':')[1];
    };

    ClientContainer.prototype.run = function(init_data) {
      var error, id_map, is_loading, page, page_data, page_id;
      this._page = this._page_map.lookup({
        location: window.location,
        user: Mediator.user()
      });
      if (!this._page) {
        error = new Error("No page matched during sync");
        console.error(error);
        return;
      }
      page_data = init_data[Strings.PAGE_DATA];
      this._page.setData(page_data);
      is_loading = this.isLoading();
      if (is_loading) {
        this._page.setBodyToLoadingView();
      } else {
        this._page.buildAndSetBody();
      }
      id_map = init_data[Strings.ID_MAP];
      this._sync(id_map);
      if (is_loading) {
        page = this._page;
        this._page.replaceLoadingWithBuild();
        page_id = this.pageId();
        this._page.setId(page_id);
      }
      return this._page.run();
    };

    ClientContainer.prototype._sync = function(id_map) {
      var _syncView;
      _syncView = function(args) {
        var error, i, id, map, subid, subids, submap, subview, subviews, temp_subid, temp_subids, view, _i, _ref, _results;
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
        for (i = _i = 0, _ref = subids.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
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
      return _syncView({
        id: this.pageId(),
        map: id_map,
        view: this._page
      });
    };

    ClientContainer.prototype.changePage = function(new_page) {
      var $body;
      this._page.remove();
      this._page = new_page;
      $body = this.$body();
      $body.html(this._page.html());
      $body.attr(Strings.PAGE_ATTR_NAME, this._page.key());
      this._page.run();
      return this._pushHistory(new_page.route.path());
    };

    ClientContainer.prototype.isLoading = function() {
      return this.$body().data(Strings.IS_LOADING);
    };

    ClientContainer.prototype.goto = function(args) {
      var clientError, error, new_page, route;
      route = args.route;
      clientError = function(error) {
        return Mediator.emit('client:error', error);
      };
      new_page = this._page_map.lookup({
        route: route,
        location: window.location,
        user: Mediator.user()
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
          new_page.buildAndSetBody();
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
