
properties = require './properties'

module.exports = required: true, handler: ->
  return if @registered 'hconfigure'
  @register 'hconfigure', (options) ->
    fnl_props = {}
    org_props = {}
    updated = 0
    options.source ?= options.destination
    @call (_, callback) ->
      options.log? "Read source properties from '#{options.source}'"
      # Populate org_props and, if merge, fnl_props
      properties.read options.ssh, options.source, (err, props) ->
        return callback err if err and err.code isnt 'ENOENT'
        org_props = if err then {} else props
        if options.merge
          fnl_props = {}
          for k, v of org_props then fnl_props[k] = v
        callback()
    @call (_, callback) ->
      return callback() unless options.default
      return callback() unless typeof options.default is 'string'
      options.log? "Read default properties from #{options.default}"
      # Populate options.default
      ssh = if options.local_default then null else options.ssh
      properties.read ssh, options.default, (err, dft) ->
        return callback err if err
        options.default = dft
        callback()
    @call ->
      return unless options.default
      # Note, default properties overwrite current ones by default, not sure
      # if this is the safest approach
      overwrite_curent = true
      options.log? "Merge default properties"
      for k, v of options.default
        v = "#{v}" if typeof v is 'number'
        fnl_props[k] = v if overwrite_curent or typeof fnl_props[k] is 'undefined' or fnl_props[k] is null
    @call ->
      options.log? "Merge user properties"
      for k, v of options.properties
        v = "#{v}" if typeof v is 'number'
        if typeof v is 'undefined' or v is null
          delete fnl_props[k]
        else if Array.isArray v
          fnl_props[k] = v.join ','
        else if typeof v isnt 'string'
          throw Error "Invalid value type '#{typeof v}' for property '#{k}'"
        else fnl_props[k] = v
    @call ->
      keys = {}
      for k in Object.keys(org_props) then keys[k] = true
      for k in Object.keys(fnl_props) then keys[k] = true unless keys[k]?
      keys = Object.keys keys
      for k in keys
        continue unless org_props[k] isnt fnl_props[k]
        options.log? "Property '#{k}' was '#{org_props[k]}' and is now '#{fnl_props[k]}'"
        updated = true
    @call ->
      options.content = properties.stringify fnl_props
      options.source = null
      @write options
