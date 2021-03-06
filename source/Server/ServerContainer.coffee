# NPM dependencies
# ------------------
# [tf](https://github.com/stephenhandley/tf)  
# [type-of-is](https://github.com/stephenhandley/type-of-is)
# [shortid](https://github.com/dylang/shortid)  
Tag  = require('tf')
Type = require('type-of-is')
ShortId = require('shortid')

# Local dependencies
# ------------------ 
# [Strings](./Strings.html)  
Strings = require('../Shared/Strings')

# ServerContainer
# ===============
# The container provides all the HTML needed outside of the body tag. 
# as well as 
class ServerContainer
  _status : 200

  # constructor
  # -----------
  # **site_name** : the name of the site serving this container
  #
  # **logo_url** : url for site logo
  constructor : (args)->
    @_site_name = args.site_name
    @_logo_url  = args.logo_url

  # _idMap
  # ------
  # Called on the server to build a map of all the view ids for 
  # the client to use for sync. 
  _idMap : ()->    
    idMap = (view)->
      map = {}
      for id, subview of view.subviews()
        map[subview.id] = idMap(subview)
      map

    idMap(@_page)

  # load
  # ----
  # Load and build the page that this container is rendering
  #
  # **page** : page to load & build
  # 
  # **callback** : callback to return (error)
  load : (args)->
    @_page   = args.page
    callback = args.callback

    if @_page.needsUser()
      @_page.setData({})
      @_page.setBodyToLoadingView()
      callback(null)

    else    
      @_page.load((error, data)=>
        unless error
          @_page.setData(data)
          @_page.buildAndSetBody()

        callback(error)
      )

  storeInitData : (args)->
    {store, callback} = args
    store.set(
      key      : @_pageKey()
      value    : @_initData()
      callback : callback
    )

  # status
  # ------
  # returns the http status
  status : ()->
    @_status

  # headers
  # -------
  # returns and custom headers for the container's page
  headers : ()->
    @_page.headers()

  # html
  # ----
  # render this container as html
  html : ()->
    # TODO
    # <link rel="shortcut icon" href="#{@favicon_url}" />
    
    """
      <!DOCTYPE html>
      <html>
        <head>
          #{@_meta()}

          <title>#{@_title()}</title>

          #{(Tag.stylesheet(href: href) for href in @_page.styles).join("\n")}
          
          #{(Tag.script(src: src) for src in @_page.scripts).join("\n")}
          
          #{@_page.head()}        
        </head>
        
        <body #{@_pageIdAttr()} #{@_pageKeyAttr()} #{@_isLoadingAttr()}>
          #{@_page.html()}
        </body>
      </html>
    """

  # text
  # ----
  # render this container as text
  text : ()->
    @_page.text()

  # json
  # ----
  # render this container as json
  json : ()->
    @_page.json()

  # *INTERNAL METHODS*
  # ------------------

  # _meta
  # -----
  # pages should have a attribute or function 'meta' that provides 
  # the following metadata
  # {
  #   title       : <title for page>
  #   description : <description of page>
  #   image       : <image for page> (optional)
  #   type        : <type for page>  (optional)
  # }
  _meta : ()->
    meta  = @_page.getMeta()

    url   = @_page.url
    title = @_title()
    image = meta.image || @_logo_url
    type  = meta.type || 'website'

    metadata = {
      name : {
        description : meta.description
        viewport    : @_page.viewport || 'width=device-width, initial-scale=1'
      }

      # Google rich snippets
      # https://support.google.com/webmasters/answer/146750?hl=en
      itemprop : {
        name        : title
        description : meta.description
        image       : image
        url         : url
      }

      # FB Open Graph 
      # http://ogp.me
      property : {
        "og:title"       : title
        "og:description" : meta.description
        "og:image"       : image
        "og:url"         : url
        "og:type"        : type
        "og:site_name"   : @_site_name
      }
    }

    # additional open graph properties specific to og:type
    if meta.og
      for k,v of meta.og
        metadata.property["og:#{k}"] = v

    # TODO: support html microdata
      
    html = Tag.meta(charset : 'utf-8') + "\n"

    for attr, m of metadata
      for name, content of m
        args = { 
          content : content
        }
        args[attr] = name
        html += Tag.meta(args) + "\n"
      
    html
    
  # _title
  # -------
  # Title for this container's page
  _title : ()->
    @_page.title() || @_site_name

  # _pageKey
  # --------
  # Page key for storing init data
  _pageKey : ()->
    unless @_page_key
      id = ShortId.generate()
      @_page_key = "#{@_page.constructor.name}:#{id}"

    @_page_key


  # initData
  # --------
  # Returns the page and id map data for this container to be
  # used in sync on the client
  _initData : ()->
    result = {}
    result[Strings.ID_MAP]    = @_idMap()
    result[Strings.PAGE_DATA] = @_page.page_data
    result

  # _pageKeyAttr
  # ------------
  # The attribute used to pass this page's id and name in 
  # the rendered html for use in client sync
  _pageKeyAttr : ()->
    page_key = @_pageKey()
    "#{Strings.PAGE_KEY_ATTR_NAME}=\"#{page_key}\""

  # _pageIdAttr
  # -----------
  # Body attribute holding the page name (useful for CSS namespacing)
  _pageIdAttr : ()->
    "id=\"#{@_page.id}\""

  # _isLoadingAttr
  # --------------
  # Used by the client to determine whether the server was
  # able to render the full page or whether its loading
  _isLoadingAttr : ()->
    "data-#{Strings.IS_LOADING}=\"#{@_page.needsUser()}\""

module.exports = ServerContainer