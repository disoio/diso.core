# NPM dependencies
# ------------------
# [jquery](https://github.com/jquery/jquery)  
# [diso.router](https://github.com/disoio/diso.router)    
$      = require('jquery')
Router = require('diso.router')

# Local dependencies
# ------------------ 
# [Mediator](./Mediator.html)  
# [PageMap](./PageMap.html)  
# [Strings](./Strings.html)  
Mediator = require('../Shared/Mediator')
PageMap  = require('../Shared/PageMap')
Strings  = require('../Shared/Strings')

# ClientContainer
# ===============
# Used by the client to sync the initial serverside render
# with the clientside page, perform navigation between and 
# within pages via HTML5 history api
class ClientContainer
  constructor : (args)->
    # [PageMap](./PageMap.html) is used for routing / page lookup
    @_page_map = new PageMap(args)
    @_initializeHistory()

  pageKey : ()->
    $('body').attr(Strings.PAGE_ATTR_NAME)

  # sync
  # ----
  # This method use the data sent in the initializeReply message to 
  # create a page and sync it with the server-rendered html that is 
  # in the current dom. 
  # 
  # A page is created using the body attribute of its constructor name
  # and passed the page_data from initializeReply. The id_map in that 
  # same message is then used to traverse the dom of and attach the 
  # view objects created in the client to their associated containers,
  # and update their ids to match those sent in the id_map (which are 
  # the ids that are present in the dom)
  # 
  # **init_data** : the initial data received from initializeReply. This 
  #                 should have two attributes: 'id_map' and 'page_data'
  sync : (init_data)->
    id_map    = init_data[Strings.ID_MAP]
    page_data = init_data[Strings.PAGE_DATA]

    [page_name, page_id] = @pageKey().split(':')

    unless page_name
      error = new Error("HTML body is missing #{Strings.PAGE_ATTR_NAME} attribute")
      return error

    # use the page map to retrieve the page by this name
    @_page = @_page_map.sync(
      name      : page_name
      location  : window.location
      data      : page_data
      container : @
    )

    unless @_page
      error = new Error("No page named #{page_name}")
      return error

    # used to traverse the view hierarchy and sync each 
    # element of the view with id_map passed via the initalizeReply
    _syncView = (args)->
      id   = args.id
      map  = args.map
      view = args.view

      view.setId(id)

      subids      = Object.keys(map)
      subviews    = view.subviews()
      temp_subids = Object.keys(subviews)

      if (subids.length != temp_subids.length)
        error = new Error("Sync failed: Mismatch between map and view")
        throw error

      if (subids.length is 0)
        return

      # recurse on subviews
      for i in [0 .. (subids.length - 1)]
        subid  = subids[i]
        submap = map[subid]

        temp_subid = temp_subids[i]
        subview    = subviews[temp_subid]
        
        _syncView(
          id   : subid
          map  : submap
          view : subview
        )

    # have the page build its views
    @_page.build()

    # sync the page (it will take care of syncing its subviews)
    _syncView(
      id   : page_id
      map  : id_map
      view : @_page
    )

    # run the page (i.e. call setup on each view)
    @_page.run()

  changePage : (new_page)->
    @_page.remove()
    @_page = new_page
    
    $body = $('body')
    $body.html(@_page.html())
    $body.attr(Strings.PAGE_ATTR_NAME, @_page.key())

    @_page.run()
    @_pushHistory(new_page.route.path()) # or just new_page.url ? 

  # goto
  # ----
  # Make a transition between pages
  # 
  # **route** : the route for new page
  goto : (args)=>
    route = args.route

    clientError = (error)->
      Mediator.emit('client:error', error)

    # get a new page for this route from the page map
    new_page = @_page_map.route(
      route     : route
      location  : window.location
      container : @
    )

    unless new_page
      error = new Error("No page for #{route.name}")
      return clientError(error)

    # TODO: make this way more robust
    #       for starters pass the JWT-token via get param or header
    unless @_supportsHistory()
      window.location = new_page.route.path()
      return

    # load the new page 
    new_page.load((error, data)=>
      if error
        return clientError(error)

      new_page.setData(data)
      new_page.build()

      @changePage(new_page)
    )

  # *HISTORY METHODS*
  # -----------------

  # _initializeHistory
  # ------------------
  # Initialize the html5 history api. Using the browser api rather 
  # than adapter and falling back to full page loads if it isn't 
  # support
  # http://diveintohtml5.info/history.html
  _initializeHistory : ()->
    if @_supportsHistory()
      $(window).on('popstate', @_onPopState)
  
  # _supportsHistory
  # ----------------
  # returns true if the user's browser supports HTML5 history
  # http://caniuse.com/#search=history
  _supportsHistory : ()->
    !!(window.history?.pushState)
  
  # _onPopState
  # -----------
  # called when user presses back button  
  # TODO: handle this correctly / integrate with router
  _onPopState : ()=>
    console.log("HANDLE POP STATE YO:" + document.location)

  # _pushHistory
  # -----------
  # add url to the history. this will change the location bar to url
  _pushHistory : (url)->
    window.history.pushState(null, null, url)

module.exports = ClientContainer