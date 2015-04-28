
###

Options include
*   `startup`: [true] or false
*   `link`: [true]
*   `write`: array
*   `name`
*   `version`
*   `version_name`
*   `etc_default` (string, array, object)
     List of filename present inside "hdp/{version}/etc/rc.d" directory to symlink
     from "/etc/rc.d", default to options.name.   
###

module.exports = (ctx) ->
  ctx.hdp_service = (options, callback) ->
    options = name: options if typeof options is 'string'
    wrap null, arguments, (options, callback) ->
      changed = false
      options.startup ?= false
      options.version_name ?= options.name
      return callback Error "Missing Option 'name'" unless options.name
      version=''
      options.version ?= ctx.config.ryba.hdp?.version
      options.version ?= 'latest'
      do_service = ->
        ctx.service
          name: "#{options.name}"
        , (err, updated) ->
          return do_end err if err
          changed = true if updated
          do_link()
      do_link = ->
        options.etc_default ?= true
        etc_default = options.etc_default
        etc_default = options.name if etc_default is true
        etc_default = [etc_default] if typeof etc_default is 'string'
        if Array.isArray etc_default
          options.etc_default = {}
          for name in etc_default
            options.etc_default[name] = {}
        ctx.execute
          cmd: """
          code=3
          if [ "#{options.version}" == "latest" ]; then
            version=`hdp-select versions | tail -1`
          elif [ "#{options.version}" == "current" ]; then
            version=`hdp-select status #{options.version_name} | sed 's/.* \\(.*\\)/\\1/'`
          else
            version='#{options.version}'
          fi
          if [ ! -d "/usr/hdp/$version" ]; then
            echo 'Failed to detect the latest HDP version'
            exit 1
          fi
          echo $version
          hdp-select set #{options.version_name} $version
          # Deal with "rc.d" startup scripts
          source="/etc/init.d/#{options.name}"
          target="/usr/hdp/$version/etc/rc.d/init.d/#{options.name}"
          create=1
          if [ -L $source ]; then
            current=`readlink $source`
            if [ ! -f $target ]; then exit 1; fi
            if [ "$target" == "$current" ]; then
              create=0
            fi
          fi
          if [ $create == '1' ]; then
            ln -sf $target $source
            code=0
          fi
          # Deal with "/etc/default" environment scripts
          for filename in #{Object.keys(options.etc_default).join(' ')}; do
            source="/etc/default/$filename"
            target="/usr/hdp/$version/etc/default/$filename"
            if [ ! -f $target ]; then
              if [ $source == "/etc/default/#{options.name}" ]; then continue; else exit 1; fi
            fi
            create=1
            if [ -L $source ]; then
              current=`readlink $source`
              if [ "$target" == "$current" ]; then
                create=0
              fi
            fi
            if [ "$create" == '1' ]; then
              ln -sf $target $source
              code=0
            fi
          done
          exit $code
          """
          code_skipped: 3
        , (err, linked, stdout, stderr) ->
          return do_end err if err
          version = string.lines(stdout)[0]
          changed = true if linked
          do_startup()
      do_startup = ->
        ctx.service
          srv_name: "#{options.name}"
          startup: options.startup
        , (err, startuped) ->
          return do_end err if err
          changed = true if startuped
          do_write()
      do_write = ->
        return do_write_etc_default() unless options.write
        ctx.write
          destination: "/usr/hdp/#{version}/etc/rc.d/init.d/#{options.name}"
          write: options.write
          backup: true
        , (err, written) ->
          return do_end err if err
          changed = true if written
          do_write_etc_default()
      do_write_etc_default = ->
        each options.etc_default
        .run (name, options, next) ->
          return next() unless options.write
          ctx.write
            destination: "/usr/hdp/#{version}/etc/default/#{name}"
            write: options.write
            backup: true
          , (err, written) ->
            return next err if err
            changed = true if written
            next()
        .then (err) -> do_end err, changed
      do_end = (err) ->
        callback err, changed
      do_service()
    # .then (err) -> callback err, changed

each = require 'each'
wrap = require 'mecano/lib/misc/wrap'
string = require 'mecano/lib/misc/string'
