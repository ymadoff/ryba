
each = require 'each'
mecano = require 'mecano'
misc = require 'mecano/lib/misc'
conditions = require 'mecano/lib/conditions'

###
Options include
*   principal
*   password
*   kadmin_principal
*   kadmin_password
*   admin_server        Optional, use "kadmin.local" if missing
*   randkey             Generate a random key
*   keytab              file to which key entry are added
*   ssh
*   log
*   stdout
*   stderr
###
module.exports = (goptions, options, callback) ->
  if arguments.length is 2
    callback = options
    options = goptions
    goptions = parallel: true
  misc.options options, (err, options) ->
    return callback err if err
    executed = 0
    each(options)
    .parallel( goptions.parallel )
    .on 'item', (options, next) ->
      return next new Error 'Property principal is required' unless options.principal
      return next new Error 'Password or randkey missing' if not options.password and not options.randkey
      modified = false
      do_kadmin = ->
        cmds = []
        if options.admin_server
          cmds.push (data, stream) ->
            if /^Password for/mg.test data
              stream.write "#{options.kadmin_password}\n"
              true
        if options.password
          cmds.push (data, stream) ->
            if /^kadmin(\.local)?:/mg.test data
              stream.write "addprinc #{options.principal}\n"
              true
          cmds.push (data, stream) ->
            if /^Enter password/mg.test data
              stream.write "#{options.password}\n"
              true
          cmds.push (data, stream) ->
            if /^Re\-enter password/mg.test data
              stream.write "#{options.password}\n"
              true
          cmds.push (data, stream) ->
            if /^Principal ".*" created/mg.test data
              modified = true
              stream.write "quit\n"
              true
            else if /already exists/mg.test data
              stream.write "quit\n"
              true
        else
          cmds.push (data, stream) ->
            if /^kadmin(\.local)?:/mg.test data
              stream.write "addprinc -randkey #{options.principal}\n"
              true
          cmds.push (data, stream) ->
            if /already exists/.test data
              cmds.push (data, stream) ->
                if /^kadmin(\.local)?:/mg.test data
                  stream.write "quit\n"
                  true
              keytab = if options.keytab then "-k #{options.keytab}" else ''
              cmd = "ktadd #{keytab} #{options.principal}"
              options.log? "Add entry to keytab #{cmd}"
              stream.write "#{cmd}\n"
              true
            else if /Principal ".*" created/.test data
              modified = true
              cmds.push (data, stream) ->
                if /^kadmin(\.local)?:/mg.test data
                  stream.write "quit\n"
                  true
              keytab = if options.keytab then "-k #{options.keytab}" else ''
              stream.write "ktadd #{keytab} #{options.principal}\n"
              true
        index = 0
        cmd = if options.admin_server
        then "kadmin -p #{options.kadmin_principal} -s #{options.admin_server}\n"
        else "kadmin.local\n"
        options.log? "Run command: #{cmd}"
        options.ssh.shell (err, stream) ->
          return next err if err
          stream.write cmd
          stream.on 'data', listener = (data, extended) ->
            options[if extended is 'stderr' then 'stderr' else 'stdout']?.write data
            cmd = cmds[index]
            if cmd? data.toString(), stream
              index++
              if index is cmds.length
                stream.end()
          stream.on 'close', ->
            do_chown()
      do_chown = () ->
        return do_chmod() if not options.keytab or not options.uid or not options.gid
        misc.file.stat options.ssh, options.keytab, (err, stat) ->
          return next err if err
          return do_chmod() if options.uid is stat.uid and options.gid is stat.gid
          misc.file.chown options.ssh, options.keytab, options.uid, options.gid, (err, stat) ->
            return next err if err
            modified = true
            do_chmod()
      do_chmod = () ->
        return do_end() if not options.keytab or not options.mode
        misc.file.stat options.ssh, options.keytab, (err, stat) ->
          return next err if err
          return do_end() if stat.mode.toString(8).substr(-3) is options.mode.toString(8).substr(-3)
          misc.file.chmod options.ssh, options.keytab, options.mode, (err, stat) ->
            return next err if err
            modified = true
            do_end()
      do_end = ->
        executed++ if modified
        next()
      conditions.all options, next, do_kadmin
    .on 'both', (err) ->
      callback err, executed
