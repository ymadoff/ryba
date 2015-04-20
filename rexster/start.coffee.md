
# Titan Server Start


    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./').configure

## Start

Start the Titan server: Rexster. You can also start the server manually with the
following command (assuming default parameter):

```
su -l rexster -c "/opt/titan/current/bin/rexster.sh --start -c titan-server-site.xml"
```

Note, there is no need to clean a zombie pid file before starting the server.


    module.exports.push name: 'Rexster # Start', label_true: 'STARTED', timeout: -1, handler: (ctx, next) ->
      {titan, rexster, realm} = ctx.config.ryba
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
        p=`$JPS -l | grep "com.tinkerpop.rexster.Application"`
        if [ -n "$p" ]; then exit 3; fi
        su -l #{rexster.user.name} -c "nohup #{path.join titan.home, 'bin', 'rexster.sh'} --start -c titan-server.xml >#{path.join rexster.log_dir, 'rexster.out'} 2>/dev/null &"
        """
        code_skipped: 3
      , next

    path = require 'path'
