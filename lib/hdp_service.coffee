  
module.exports = (ctx) ->
  # Options include
  # startup: [true] or false
  # link: [true]
  # write: array
  # version_name
  ctx.hdp_service = (options, callback) ->
    options = name: options if typeof options is 'string'
    options = [options] unless Array.isArray options
    changed = false
    each options
    .run (options, next) ->
      options.startup ?= false
      # options.link ?= true
      options.version_name ?= options.name
      return next Error "Missing Option 'name'" unless options.name
      version = null
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
          version=`hdp-select status #{options.version_name} | sed 's/.* \\(\\d*\\)/\\1/'`
          if [ ! -d "/usr/hdp/$version" ]; then
            version=`yum repolist | egrep HDP-[0-9] | sed 's/^HDP-\\([0-9\\.]*\\).*$/\\1/'`
            version=`ls --format=single-column /usr/hdp | grep ${version} | tail -1`
            if [ ! -d "/usr/hdp/$version" ]; then
              echo 'Failed to detect the latest HDP version'
              exit 1
            fi
          fi
          echo $version
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
    .then (err) -> callback err, changed

each = require 'each'
string = require 'mecano/lib/misc/string'
