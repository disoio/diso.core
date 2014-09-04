# NPM dependencies
# ----------------
# [type-of-is](https://github.com/stephenhandley/type-of-is)  
# [router](https://github.com/disoio/diso.router)  
Type   = require('type-of-is')
Router = require('diso.router')

# helper for throwing errors when page missing
_missingPageError = (route)->
  new Error("Missing page for route: #{route.name}")

# PageMap
# =======
# This class handles routing and page lookup
class PageMap
  _router : null
  _pages  : {}
  _routes : {}

  # object that maps from a route name to the 
  # constructor for its Page 
  _page_by_route_name : {}
  
  # constructor
  # -----------
  # ### required args
  # **map** : map of routes to pages  
  constructor : (args)->
    @_store = args.store
    @_process(args.map)
    @_router = new Router(@_routes)

  # _process
  # --------
  # Process the map to yield list of routes for router
  # and also allow for page lookup via route name and 
  # constructor name
  _process : (map)->
    for name,route of map
      for attr in ['page', 'route']
        unless route[attr]
          throw new Error("You're missing #{attr} for '#{name}' in app's map")

      page  = route.page
      route = route.route

      @_pages[page.name] = page

      # add route for base route
      @_addRoute(
        name  : name
        route : route
        page  : page
      )

      # add routes for all subroutes
      for name,subroute of map.subroutes
        subroute = route + subroute

        @_addRoute(
          name  : name
          route : subroute
          page  : page
        )

  # _addRoute
  # ---------
  # Add a route
  _addRoute : (args)->
    name  = args.name
    route = args.route
    page  = args.page

    @_routes[name]             = route
    @_page_by_route_name[name] = page

  # handle
  # ------
  # this function is called by the [connect](https://github.com/senchalabs/connect) 
  # middleware pipeline on server. It looks up a page for 
  # the route added by the router middleware and adds the 
  # page constructor for that route to the request
  handle : (req, res, next)->
    @_router.handle(req, res, ()=>
      Page = @_pageForRouteName(req.route.name)
      
      if Page
        headers = req.headers
        page = new Page(
          store  : @_store
          route  : req.route
          origin : "#{headers.protocol}#{headers.host}"
        )
        req.page = page
        next()
      else
        error = _missingPageError(route)
        next(error)
    )

  # _pageForRouteName
  # -----------------
  # Lookup and return the page class for a given route name
  # returns null if no page is found matching route's name
  _pageForRouteName : (name)->
    if name of @_page_by_route_name
      @_page_by_route_name[name]
    else
      null

  # page 
  # ----
  # Lookup and return a page by its name
  page : (name)->
    @_pages[name]

  # sync
  # ----
  # Create the page for the client. This is called in the initial
  # client loading process by the ClientContainer's sync method.
  # It takes care of passing the initial data to the page. 
  sync : (args)->
    name      = args.name
    location  = args.location
    container = args.container
    data      = args.data

    Page = @page(name)
    unless Page
      return null
    
    path = location.pathname + location.search + location.hash
    route = @_router.match(path : path)

    new Page(
      store     : @_store
      route     : route
      origin    : location.origin
      container : container
      data      : data
    )

  # route
  # -----
  # Lookup and create a page for the given route
  # throws error if no page matches the route. This 
  # is called by the ClientContainer's goto method
  route : (args)->
    route     = args.route
    location  = args.location
    container = args.container

    matched_route = @_router.match(route : route)

    Page = @_pageForRouteName(matched_route.name)

    unless Page 
      error = _missingPageError(matched_route)
      throw error

    new Page(
      store     : @_store
      route     : route
      origin    : location.origin
      container : container
    )

module.exports = PageMap