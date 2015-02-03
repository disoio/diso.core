(function() {
  var $, ClientContainer, Mediator, PageMap, Router, Strings, clientError,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $ = require('jquery');

  Router = require('diso.router');

  Mediator = require('../Shared/Mediator');

  PageMap = require('../Shared/PageMap');

  Strings = require('../Shared/Strings');

  clientError = function(error) {
    return Mediator.emit('client:error', error);
  };

  ClientContainer = (function() {
    ClientContainer.prototype._$body = null;

    ClientContainer.prototype._has_changed_page = false;

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
      return this.$body().attr(Strings.PAGE_KEY_ATTR_NAME);
    };

    ClientContainer.prototype.pageId = function() {
      return this.$body().attr('id');
    };

    ClientContainer.prototype.setup = function(init_data) {
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
      return this._page.setup();
    };

    ClientContainer.prototype.isLoading = function() {
      return this.$body().data(Strings.IS_LOADING);
    };

    ClientContainer.prototype.goto = function(args) {
      var new_page, route;
      route = args.route;
      new_page = this._page_map.lookup({
        route: route,
        location: window.location,
        user: Mediator.user()
      });
      if (this._supportsHistory()) {
        return this._changePage({
          page: new_page,
          push: true
        });
      } else {
        return window.location = new_page.route.path();
      }
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

    ClientContainer.prototype._changePage = function(args) {
      var new_page, push_history;
      new_page = args.page;
      push_history = args.push;
      this._has_changed_page = true;
      return new_page.load((function(_this) {
        return function(error, data) {
          var $body;
          if (error) {
            return clientError(error);
          }
          new_page.setData(data);
          new_page.buildAndSetBody();
          _this._page.remove();
          $body = _this.$body();
          $body.html(new_page.html());
          $body.attr(Strings.PAGE_KEY_ATTR_NAME, new_page.key());
          $body.attr('id', new_page.constructor.name);
          new_page.setup();
          if (push_history) {
            _this._pushHistory(new_page.route.path());
          }
          return _this._page = new_page;
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

    ClientContainer.prototype._onPopState = function(event) {
      var new_page;
      if (this._has_changed_page) {
        new_page = this._page_map.lookup({
          location: window.location,
          user: Mediator.user()
        });
        return this._changePage({
          page: new_page,
          push: false
        });
      }
    };

    ClientContainer.prototype._pushHistory = function(url) {
      return window.history.pushState(null, null, url);
    };

    return ClientContainer;

  })();

  module.exports = ClientContainer;

}).call(this);
