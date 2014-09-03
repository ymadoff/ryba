
    each = require 'each'
    misc = require 'mecano/misc'
    conditions = require 'mecano/misc/conditions'
    child = require 'mecano/misc/child'

    module.exports =

      mkdir: (goptions, options, callback) ->
        [goptions, options, callback] = misc.args arguments
        result = child()
        finish = (err, created, stdout, stderr) ->
          callback err, created, stdout, stderr if callback
          result.end err, created
        misc.options options, (err, options) ->
          return finish err if err
          mkdired = 0
          each( options )
          .parallel(goptions.parallel)
          .on 'item', (options, next) ->
            return next new Error "Required Option: \"destination\""
            options.destination = "/user/{options.username}/#{options.destination}" unless options.destination.substr(0,1) is '/'
            modified = false
            stat = null
            cmd: (cmd) ->
              if options.security is 'kerberos'
              then "echo #{options.password} | kinit {options.username} >/dev/null && {\n#{cmd}\n}"
              else "su -l #{options.username} -c \"#{cmd}\""
            do_stat = ->
              mecano.execute
                cmd: cmd """
                curl --negotiate -u : http://#{host}:#{name}/webhdfs/v1#{options.destination}?op=GETFILESTATUS"
                """
                # code_skipped: 2
              , (err, _, stdout) ->
                return next err if err
                stat = JSON.parse stdout
                if stdout.RemoteException
                  if stdout.RemoteException.exception is 'FileNotFoundException'
                    do_create()
                  else
                    next new Error stdout.RemoteException.message
                else
                  do_chmod()
                modified = true if created
            do_create = ->
              permission = "&permission=#{misc.mode.stringify options.mode}" if options.mode
              mecano.execute
                cmd: cmd """
                curl --negotiate -u : -X PUT http://#{host}:#{name}/webhdfs/v1#{options.destination}?op=MKDIRS#{permission}"
                """
                # code_skipped: 2
              , (err, _, stdout) ->
                do_chown()
            do_chmod = ->
              return do_chown() unless options.mode
              permission = "&permission=#{misc.mode.stringify options.mode}"
              mecano.execute
                cmd: cmd """
                curl --negotiate -u : -X PUT http://#{host}:#{name}/webhdfs/v1#{options.destination}?op=SETPERMISSION#{permission}"
                """
                # code_skipped: 2
              , (err, _, stdout) ->
                do_chown()
            do_chown = ->
              return do_end() unless options.uid

            do_end = ->
              mkdired++ if modified
            conditions.all options, next, do_stat
          .on 'both', (err) ->
            finish err, mkdired

        result
