(function() {
  var Mediator, PageMap, Router, Type, _missingPageError;

  Type = require('type-of-is');

  Router = require('diso.router');

  Mediator = require('./Mediator');

  _missingPageError = function(route) {
    return new Error("Missing page for route: " + route.name);
  };

  PageMap = (function() {
    PageMap.prototype._router = null;

    PageMap.prototype._pages = {};

    PageMap.prototype._routes = {};

    PageMap.prototype._page_by_route_name = {};

    function PageMap(args) {
      this._models = args.models;
      this._process(args.map);
      this._router = new Router(this._routes);
    }

    PageMap.prototype.handle = function(request, response, next) {
      return this._router.handle(request, response, (function(_this) {
        return function() {
          var Page, error, headers, page;
          Page = _this._pageForRouteName(request.route.name);
          if (Page) {
            headers = request.headers;
            page = new Page({
              models: _this._models,
              user: request.user,
              route: request.route,
              origin: "" + headers.protocol + headers.host
            });
            request.page = page;
            return next();
          } else {
            error = _missingPageError(route);
            return next(error);
          }
        };
      })(this));
    };

    PageMap.prototype.page = function(name) {
      return this._pages[name];
    };

    PageMap.prototype.lookup = function(args) {
      var Page, error, location, matched_route, path, route, user;
      route = args.route;
      location = args.location;
      user = args.user;
      matched_route = route ? this._router.match({
        route: route
      }) : (path = location.pathname + location.search + location.hash, this._router.match({
        path: path
      }));
      Page = this._pageForRouteName(matched_route.name);
      if (!Page) {
        error = _missingPageError(matched_route);
        throw error;
      }
      return new Page({
        models: this._models,
        user: user,
        route: matched_route,
        origin: location.origin
      });
    };

    PageMap.prototype._process = function(map) {
      var attr, base_route, full_subroute, name, page, route, subroute, _i, _len, _ref, _results;
      _results = [];
      for (name in map) {
        route = map[name];
        _ref = ['page', 'route'];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          attr = _ref[_i];
          if (!route[attr]) {
            throw new Error("You're missing " + attr + " for '" + name + "' in app's map");
          }
        }
        page = route.page;
        base_route = route.route;
        this._pages[page.name] = page;
        this._addRoute({
          name: name,
          route: base_route,
          page: page
        });
        if ('subroutes' in route) {
          _results.push((function() {
            var _ref1, _results1;
            _ref1 = route.subroutes;
            _results1 = [];
            for (name in _ref1) {
              subroute = _ref1[name];
              full_subroute = base_route + subroute;
              _results1.push(this._addRoute({
                name: name,
                route: full_subroute,
                page: page
              }));
            }
            return _results1;
          }).call(this));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    PageMap.prototype._addRoute = function(args) {
      var name, page, route;
      name = args.name;
      route = args.route;
      page = args.page;
      this._routes[name] = route;
      return this._page_by_route_name[name] = page;
    };

    PageMap.prototype._pageForRouteName = function(name) {
      if (name in this._page_by_route_name) {
        return this._page_by_route_name[name];
      } else {
        return null;
      }
    };

    return PageMap;

  })();

  module.exports = PageMap;

}).call(this);
