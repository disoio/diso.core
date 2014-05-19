Utils = {
  parseAcceptHeader : (str)->
    index = 0
    str.split(/,\s+/).map((accept_str)->
      parts = accept_str.split(/;\s+/)
      [type, subtype] = parts.shift().split('/')
      params = {
        q: 1.0
      }
      
      # RFC is unclear about level param so don't treat that specially
      # http://stackoverflow.com/questions/13890996/http-accept-level
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
      for param in parts
        [name, val] = param.split('=')
        if (name is 'q')
          val = parseFloat(val)
        params[name] = val
      
      {
        index   : index++
        type    : type
        subtype : subtype
        params  : params
      }      
    ).sort((a, b)->
      if (a.params.q is b.params.q) 
        a.index - b.index
      else
        b.params.q - a.params.q
    )
}

module.exports = Utils