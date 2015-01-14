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
  # **models** : models used by pages to get data
  #
  # **map** : map of routes to pages
  constructor : (args)->
    @_models = args.models
    @_process(args.map)
    @_router = new Router(@_routes)

  # *ROUTE HANDLING / LOOKUP*
  # -------------------------

  # handle
  # ------
  # this function is called by the [connect](https://github.com/senchalabs/connect) 
  # middleware pipeline on server. It looks up a page for 
  # the route added by the router middleware and adds the 
  # page constructor for that route to the request
  #
  # **request,response,next**: the standard connect middleware trio
  handle : (request, response, next)->
    @_router.handle(request, response, ()=>
      Page = @_pageForRouteName(request.route.name)
      
      if Page
        # if a page is found matching the route, add to request
        headers = request.headers

        protocol = if request.connection.encrypted
          'https'
        else
          'http'

        page = new Page(
          models : @_models
          user   : request.user
          route  : request.route
          origin : "#{protocol}://#{headers.host}"
        ) 

        request.page = page
        next()
      else
        # trigger an error for a missing page
        error = _missingPageError(route)
        next(error)
    )

  # page 
  # ----
  # Lookup and return a page by its name
  #
  # **name** : the name of the page
  page : (name)->
    @_pages[name]

  # lookup
  # ------
  # Lookup and create a page for the given route throws error
  # if no page matches the route. 
  #
  # **route** : the route to use for lookup
  #
  # **location** : the current window.location
  # 
  # **user** : the current user
  lookup : (args)-> 
    route    = args.route
    location = args.location
    user     = args.user

    matched_route = if route
      @_router.match(route : route)
    else
      path  = location.pathname + location.search + location.hash
      @_router.match(path : path)  

    Page = @_pageForRouteName(matched_route.name)

    unless Page 
      error = _missingPageError(matched_route)
      throw error

    new Page(
      models    : @_models
      user      : user
      route     : matched_route
      origin    : location.origin
    )


  # *INTERNAL METHODS*
  # ------------------

  # _process
  # --------
  # Process the map to yield list of routes for router
  # and also allow for page lookup via route name and 
  # constructor name
  #
  # **map** : the map to process
  _process : (map)->
    for name,route of map
      for attr in ['page', 'route']
        unless route[attr]
          throw new Error("You're missing #{attr} for '#{name}' in app's map")

      page       = route.page
      base_route = route.route

      @_pages[page.name] = page

      # add route for base route
      @_addRoute(
        name  : name
        route : base_route
        page  : page
      )

      # add routes for all subroutes
      if ('subroutes' of route)
        for name,subroute of route.subroutes
          full_subroute = base_route + subroute

          @_addRoute(
            name  : name
            route : full_subroute
            page  : page
          )

  # _addRoute
  # ---------
  # Add a route to the router
  # 
  # **name** : route name
  # **route** : the route
  # **page** : page for this route
  _addRoute : (args)->
    name  = args.name
    route = args.route
    page  = args.page

    @_routes[name]             = route
    @_page_by_route_name[name] = page

  # _pageForRouteName
  # -----------------
  # Lookup and return the page class for a given route name
  # returns null if no page is found matching route's name
  #
  # **name** : route name to lookup page for
  _pageForRouteName : (name)->
    if name of @_page_by_route_name
      @_page_by_route_name[name]
    else
      null

module.exports = PageMap