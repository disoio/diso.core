# NPM dependencies
# ------------------
# [tf](https://github.com/stephenhandley/tf)  
# [type-of-is](https://github.com/stephenhandley/type-of-is)  
Tag  = require('tf')
Type = require('type-of-is')

# Local dependencies
# ------------------ 
# [Strings](../Shared/Strings.html)  
Strings = require('../Shared/Strings')

# ServerContainer
# ===============
# the container provides all the HTML needed outside of the body tag. 
#
class ServerContainer
  _init_page_data : null
  _status : 200

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

  load : (args)->
    @_page   = args.page
    callback = args.callback

    @_page.load((error, data)=>
      unless error
        @_page.setData(data)
        @_page.build()
      
      callback(error)
    )

  initData : ()->
    result = {}
    result[Strings.ID_MAP] = @_idMap()
    result[Strings.PAGE_DATA] = @_page.data
    result

  # _pageAttr
  # ---------
  _pageAttr : ()->
    "#{Strings.PAGE_ATTR_NAME}=\"#{@pageKey()}\""

  pageKey : ()->
    "#{@_page.constructor.name}:#{@_page.id}"

  status : ()->
    @_status

  # meta
  # ----
  # pages should have a attribute or function 'meta' that provides 
  # the following metadata
  # {
  #   title       : <title for page>
  #   description : <description of page>
  #   image       : <image for page> (optional)
  #   type        : <type for page>  (optional)
  # }
  _meta : ()->
    meta  = @_page.meta
    if Type(meta, Function)
      meta = meta()

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
    
  _title : ()->
    @_page.title() || @_site_name

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

module.exports = ServerContainer