
each = require 'each'
{EventEmitter} = require 'events'

mecano = require 'mecano'
conditions = require 'mecano/lib/conditions'
misc = require 'mecano/lib/misc'
child = require 'mecano/lib/child'
properties = require './properties'

###
sept 2nd, 2013: need the [patched version](https://github.com/wdavidw/xmlbuilder-js/)
to handle empty strings
Options includes:
*   `merge`: Merge with destination file
*   `default`: Path to a file or object of properties used as default values.   
*   `local_default`: Read the default file from the local filesystem (only apply if `default` is a string).   
###
module.exports = (ctx, options, callback) ->
  result = child mecano
  finish = (err, configured) ->
    callback err, configured if callback
    result.end err, configured
  misc.options options, (err, options) ->
    return finish err if err
    configured = 0
    fnl_props = {}
    org_props = {}
    each( options )
    .on 'item', (options, next) ->
      updated = 0
      options.source ?= options.destination
      do_read_source = ->
        ctx.log? "Read source properties from '#{options.source}'"
        # Populate org_props and, if merge, fnl_props
        properties.read ctx.ssh, options.source, (err, props) ->
          return next err if err and err.code isnt 'ENOENT'
          org_props = if err then {} else props
          if options.merge
            fnl_props = {}
            for k, v of org_props then fnl_props[k] = v
          do_load_default()
      do_load_default = () ->
        return do_merge() unless options.default
        return do_default() unless typeof options.default is 'string'
        ctx.log? "Read default properties from #{options.default}"
        # Populate options.default
        ssh = if options.local_default then null else ctx.ssh
        properties.read ssh, options.default, (err, dft) ->
          return next err if err
          options.default = dft
          do_default()
      do_default = () ->
        ctx.log? "Merge default properties"
        for k, v of options.default
          v = "#{v}" if typeof v is 'number'
          # if typeof v is 'undefined' or v is null
          # then delete fnl_props[k]
          # else fnl_props[k] = v
          fnl_props[k] = v if typeof fnl_props[k] is 'undefined' or fnl_props[k] is null
        do_merge()
      do_merge = () ->
        ctx.log? "Merge user properties"
        for k, v of options.properties
          v = "#{v}" if typeof v is 'number'
          if typeof v is 'undefined' or v is null
          then delete fnl_props[k]
          else fnl_props[k] = v
        do_compare()
      do_compare = ->
        keys = {}
        for k in Object.keys(org_props) then keys[k] = true
        for k in Object.keys(fnl_props) then keys[k] = true unless keys[k]?
        keys = Object.keys keys
        for k in keys
          continue unless org_props[k] isnt fnl_props[k]
          ctx.log? "Property '#{k}' was '#{org_props[k]}' and is now '#{fnl_props[k]}'"
          updated = true
        do_save()
      do_save = ->
        return next() unless updated
        ctx.log? "Save properties"
        configured++
        options.content = properties.stringify fnl_props
        options.source = null
        ctx.write options, (err, written) ->
          next err
      conditions.all options, next, do_read_source
    .on 'both', (err) ->
      finish err, configured
  result






