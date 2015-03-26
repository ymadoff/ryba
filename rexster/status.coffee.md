
# Rexster Status

Run the command `./bin/ryba status -m ryba/titan/rexster` to retrieve the status
of the Titan server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./').configure

## Status

Discover the server status.

    module.exports.push name: 'Rexster # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: """
        JPS=
        for maybejps in jps "${JAVA_HOME}/bin/jps"; do
          type "$maybejps" >/dev/null 2>&1
          if [ $? -eq 0 ]; then
            JPS="$maybejps"
            break
          fi
        done
        p = `$JPS -l | grep "com.tinkerpop.rexster.Application"`
        if [ -n "$p" ]; then exit 3; fi
        """
        code_skipped: 3
      , next
