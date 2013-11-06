
each = require 'each'
{EventEmitter} = require 'events'

conditions = require 'mecano/lib/conditions'
misc = require 'mecano/lib/misc'
child = require 'mecano/lib/child'
properties = require './properties'
mecano = require 'mecano'

###
sept 2nd, 2013: need the [patched version](https://github.com/wdavidw/xmlbuilder-js/)
to handle empty strings
Options includes:
-   `default`: Path to a file or object of properties used as default values.   
-   `local_default`: Read the default file from the local filesystem (only apply if `default` is a string).   
###
module.exports = (options, callback) ->
  result = child mecano
  finish = (err, configured) ->
    callback err, configured if callback
    result.end err, configured
  misc.options options, (err, options) ->
    return finish err if err
    configured = 0
    each( options )
    .on 'item', (options, next) ->
      updated = 0
      options.source ?= options.destination
      do_read = ->
        options.log? "Read source properties from '#{options.source}'"
        properties.read options.ssh, options.source, (err, props) ->
          return next err if err and err.code isnt 'ENOENT'
          props = {} if err
          do_load_default props
      do_load_default = (props) ->
        return do_merge props unless options.default
        return do_default props unless typeof options.default is 'string'
        options.log? "Read default properties from #{options.default}"
        ssh = if options.local_default then null else options.ssh
        properties.read ssh, options.default, (err, dft) ->
          return next err if err
          options.default = dft
          do_default props
      do_default = (props) ->
        options.log? "Merge default properties"
        for k, v of options.default
          v = "#{v}" if typeof v is 'number'
          unless props[k]?
            updated = true
            props[k] = v
        do_merge props
      do_merge = (props) ->
        options.log? "Merge user properties"
        for k, v of options.properties
          v = "#{v}" if typeof v is 'number'
          if typeof v is 'undefined' or v is null
            delete props[k]
          else if props[k] isnt v
            options.log? "Property '#{k}' was '#{v}' and is now '#{props[k]}'"
            updated = true
            props[k] = v
        do_save props
      do_save = (props) ->
        return next() unless updated
        options.log? "Save properties"
        configured++
        properties.write options.ssh, options.destination, props, (err) ->
          next err
      conditions.all options, next, do_read
    .on 'both', (err) ->
      finish err, configured
  result






