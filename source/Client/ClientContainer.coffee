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

clientError = (error)->
  Mediator.emit('client:error', error)

# ClientContainer
# ===============
# Used by the client to sync the initial serverside render
# with the clientside page, perform navigation between and 
# within pages via HTML5 history api
class ClientContainer

  _$body : null

  _has_changed_page : false

  constructor : (args)->
    # [PageMap](./PageMap.html) is used for routing / page lookup
    @_page_map = new PageMap(args)
    @_initializeHistory()

  $body : ()->
    unless @_$body
      @_$body = $('body')

    @_$body
  
  # pageKey
  # -------
  pageKey : ()->
    @$body().attr(Strings.PAGE_ATTR_NAME)

  # pageId
  # -------
  pageId : ()->
    @pageKey().split(':')[1]

  # setup
  # -----
  # The initializeReply contains two pieces of data that the client 
  # needs: initial_data used to render the page on the server, and an
  # id_map of views that make up the page. The client looks up the name 
  # of the page via the "data-page" body attribute, and then instantiates
  # the page of that name with initial_data and id_map. The page syncs 
  # with the dom and handles user interaction, delegating to Mediator.send
  # to relay messages to/from the server via this client's send method
  #
  # **init_data** : ... 
  setup : (init_data)->
    # use the page map to retrieve page for this location
    @_page = @_page_map.lookup(
      location : window.location
      user     : Mediator.user()
    )

    unless @_page
      error = new Error("No page matched during sync")
      console.error(error)
      return

    page_data = init_data[Strings.PAGE_DATA]
    @_page.setData(page_data)

    is_loading = @isLoading()

    # if loading temporarily set body to loading 
    # view before sync. it will get reset by the
    # call to page.build after sync. otherwise
    # call build to setup the existing, already
    # fully loaded page
    if is_loading
      @_page.setBodyToLoadingView()
    else
      @_page.buildAndSetBody()

    id_map = init_data[Strings.ID_MAP]
    @_sync(id_map)
    
    # if the page was loading, then we need to 
    # rerender it with the data we just pulled 
    # down in initializeReply
    if is_loading
      page = @_page
      @_page.replaceLoadingWithBuild()
      page_id = @pageId()
      @_page.setId(page_id)

    @_page.setup()

  # needsUser
  # ---------
  isLoading : ()->
    @$body().data(Strings.IS_LOADING)

  # goto
  # ----
  # Make a transition between pages
  # 
  # **route** : the route for new page
  goto : (args)=>
    route = args.route

    # get a new page for this route from the page map
    new_page = @_page_map.lookup(
      route     : route
      location  : window.location
      user      : Mediator.user()
    )

    if @_supportsHistory()
      @_changePage(
        page : new_page
        push : true
      )
    else
      # TODO: make this way more robust
      #       for starters pass the JWT-token via get param or header
      window.location = new_page.route.path()

  # _sync
  # -----
  # This method uses the data sent in the initializeReply message to 
  # create a page and sync it with the server-rendered html that is 
  # in the current dom. 
  # 
  # A page is created using the window's location and then passed the 
  # data that was sent down in the initializeReply. The id_map in that 
  # message used to traverse the dom of and attach the view objects 
  # created in the client to their associated containers, and update 
  # their ids to match those sent in the id_map (which are the ids 
  # that are present in the dom)
  # 
  # **id_map** : the id map used for syncing this page and its views
  #              with the existing dom
  _sync : (id_map)->
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

    # sync the page (it will take care of syncing its subviews)
    _syncView(
      id   : @pageId()
      map  : id_map
      view : @_page
    )

  # _changePage
  # -----------
  _changePage : (args)->
    new_page     = args.page
    push_history = args.push

    @_has_changed_page = true

    new_page.load((error, data)=>
      if error
        return clientError(error)

      new_page.setData(data)
      new_page.buildAndSetBody()
    
      @_page.remove()
    
      $body = @$body()
      $body.html(new_page.html())
      $body.attr(Strings.PAGE_ATTR_NAME, new_page.key())

      new_page.setup()

      if push_history
        @_pushHistory(new_page.route.path()) # or new_page.url

      @_page = new_page
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
  _onPopState : (event)=>
    if @_has_changed_page
      new_page = @_page_map.lookup(
        location  : window.location
        user      : Mediator.user()
      )
      
      @_changePage(
        page : new_page
        push : false
      )

  # _pushHistory
  # -----------
  # add url to the history. this will change the location bar to url
  _pushHistory : (url)->
    window.history.pushState(null, null, url)

module.exports = ClientContainer