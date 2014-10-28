# NPM dependencies
# ------------------
# [tf](https://github.com/stephenhandley/tf)  
# [type-of-is](https://github.com/stephenhandley/type-of-is)  
Tag  = require('tf')
Type = require('type-of-is')

# Local dependencies
# ------------------ 
# [Strings](./Strings.html)  
Strings = require('../Shared/Strings')

# ServerContainer
# ===============
# The container provides all the HTML needed outside of the body tag. 
# as well as 
class ServerContainer
  _init_page_data : null
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

    if @_page.canLoad()
      @_page.load((error, data)=>
        unless error
          @_page.setData(data)
          @_page.build()
        
        callback(error)
      )

    else
      callback(null, null)

  # initData
  # --------
  # Returns the page and id map data for this container to be
  # used in sync on the client
  initData : ()->
    result = {}
    result[Strings.ID_MAP] = @_idMap()
    result[Strings.PAGE_DATA] = @_page.data
    result

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
        
        <body #{@_pageAttr()}>
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

  # _pageAttr
  # ---------
  # The attribute used to pass this page's id and name in 
  # the rendered html for use in client sync
  _pageAttr : ()->
    "#{Strings.PAGE_ATTR_NAME}=\"#{@_page.key()}\""


module.exports = ServerContainer