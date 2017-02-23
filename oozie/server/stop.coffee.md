
# Oozie Server Stop

Run the command `./bin/ryba stop -m ryba/oozie/server` to stop the Oozie
server using Ryba.

Stop the Oozie service. You can also stop the server manually with the
following command:

```
service stop oozie
su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozied.sh stop"
```

The file storing the PID is "/var/run/oozie/oozie.pid".

    module.exports = header: 'Oozie Server Stop', label_true: 'STOPPED', timeout: -1, handler: ->
      {oozie} = @config.ryba
      @service.stop
        name: 'oozie'
        if_exists: '/etc/init.d/oozie'

## Stop Clean Logs

      @call
        header: 'Stop Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
        handler: ->
          @system.execute
            cmd: 'rm /var/log/oozie/*'
            code_skipped: 1
