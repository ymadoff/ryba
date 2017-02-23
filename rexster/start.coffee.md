
# Titan Server Start

Start the Titan server: Rexster. You can also start the server manually with the
following command (assuming default parameter):

```
su -l rexster -c "/opt/titan/current/bin/rexster.sh --start -c titan-server-site.xml"
```

Note, there is no need to clean a zombie pid file before starting the server.


    module.exports = header: 'Rexster Start', label_true: 'STARTED', handler: ->
      {titan, rexster} = @config.ryba
      @system.execute
        cmd: """
        if ps aux | grep "com.tinkerpop.rexster.Application" | grep -v grep; then exit 3; fi
        su -l #{rexster.user.name} -c "#{path.join titan.home, 'bin', 'rexster.sh'} --start -c titan-server.xml </dev/null >#{path.join rexster.log_dir, 'rexster.out'} 2>&1 &"
        """
        code_skipped: 3

## Dependencies

    path = require 'path'
