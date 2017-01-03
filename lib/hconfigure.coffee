
properties = require './properties'

###

Options includes
*   `merge`
*   `target`
*   `source` (alias of `target`)
*   `default`
*   `local_default`
*   `properties`
###

module.exports = (options) ->
  fnl_props = {}
  org_props = {}
  # alias
  options.local ?= options.local_source
  # options.source ?= options.target
  throw Error 'Deprecated option: default' if options.default
  throw Error 'Deprecated option: local_default' if options.local_default
  options.transform ?= null
  throw Error "Invalid options: \"transform\"" if options.transform and typeof options.transform isnt 'function'
  @call (_, callback) ->
    options.log? message: "Read target properties from '#{options.target}'", level: 'DEBUG', module: 'ryba/lib/hconfigure'
    # Populate org_props and, if merge, fnl_props
    properties.read options.ssh, options.target, (err, props) ->
      return callback err if err and err.code isnt 'ENOENT'
      org_props = if err then {} else props
      if options.merge
        fnl_props = {}
        for k, v of org_props then fnl_props[k] = v
      callback()
  @call (_, callback) ->
    return callback() unless options.source
    return callback() unless typeof options.source is 'string'
    options.log? message: "Read source properties from #{options.source}", level: 'DEBUG', module: 'ryba/lib/hconfigure'
    # Populate options.source
    ssh = if options.local then null else options.ssh
    properties.read ssh, options.source, (err, dft) ->
      return callback err if err
      options.source = dft
      callback()
  @call ->
    return unless options.source
    # Note, source properties overwrite current ones by source, not sure
    # if this is the safest approach
    overwrite_curent = true
    options.log? message: "Merge source properties", level: 'DEBUG', module: 'ryba/lib/hconfigure'
    for k, v of options.source
      v = "#{v}" if typeof v is 'number'
      fnl_props[k] = v if overwrite_curent or typeof fnl_props[k] is 'undefined' or fnl_props[k] is null
  @call ->
    options.log? message: "Merge user properties", level: 'DEBUG', module: 'ryba/lib/hconfigure'
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
    return unless options.transform
    fnl_props = options.transform fnl_props
  @call ->
    keys = {}
    for k in Object.keys(org_props) then keys[k] = true
    for k in Object.keys(fnl_props) then keys[k] = true unless keys[k]?
    keys = Object.keys keys
    for k in keys
      continue unless org_props[k] isnt fnl_props[k]
      options.log? message: "Property '#{k}' was '#{org_props[k]}' and is now '#{fnl_props[k]}'", level: 'WARN', module: 'ryba/lib/hconfigure'
  @call ->
    options.content = properties.stringify fnl_props
    options.source = null
    options.header = null
    @file options
