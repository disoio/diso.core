# NPM dependencies
# ------------------
# [jquery](https://github.com/jquery/jquery)  
# [diso.router](https://github.com/disoio/diso.router)    
$      = require('jquery')
Router = require('diso.router')

# Local dependencies
# ------------------ 
# [Mediator](../Shared/Mediator.html)  
# [PageMap](../Shared/PageMap.html)  
# [Strings](../Shared/Strings.html)  
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
  # and passed the view_data from initializeReply. The id_map in that 
  # same message is then used to traverse the dom of and attach the 
  # view objects created in the client to their associated containers,
  # and update their ids to match those sent in the id_map (which are 
  # the ids that are present in the dom)
  sync : (init_data)->
    id_map    = init_data[Strings.ID_MAP]
    page_data = init_data[Strings.PAGE_DATA]

    [page_name, page_id] = @pageKey().split(':')

    unless page_name
      error = new Error("HTML body is missing #{Strings.PAGE_ATTR_NAME} attribute")
      return error

    @_page = @_page_map.sync(
      name      : page_name
      location  : window.location
      data      : page_data
      container : @
    )

    unless @_page
      error = new Error("No page named #{page_name}")
      return error

    _syncView = (args)->
      id   = args.id
      map  = args.map
      view = args.view

      view.setNode(id)

      subids      = Object.keys(map)
      subviews    = view.subviews()
      temp_subids = Object.keys(subviews)

      if (subids.length != temp_subids.length)
        error = new Error("Sync failed: Mismatch between map and view")
        throw error

      if (subids.length is 0)
        return

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

    try
      @_page.build()

      _syncView(
        id   : page_id
        map  : id_map
        view : @_page
      )

      @_page.run()

      return null

    catch error
      return error

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

  pushPage  : ()->
  popPage   : ()->

  goto : (args)=>
    console.log("GOTO!")
    console.log(args)
    
    route      = args.route
    transition = args.transition

    new_page = @_page_map.route(
      route     : route
      location  : window.location
      container : @
    )

    unless new_page
      error = new Error("No page for #{route.name}")
      return Mediator.emit('client:error', error)

    unless @_supportsHistory()
      # TODO : find way to pass the JWT-token via get param or header
      window.location = new_page.route.path()
      return

    new_page.load((error)=>
      console.log("LOADED PAGE!!!!")
      @_pushHistory(page.route.path())
    )

  setBody : (body)->
    if @body
      @removeSubview(@body)
    @body = body
    @addSubview(@body)
  
  swapBody : (new_body)->
    @body.removeBehaviors()
    $body = $("##{@body.id}")
    $body.replaceWith(new_body.html())
    @setBody(new_body)
    new_body.run()

module.exports = ClientContainer