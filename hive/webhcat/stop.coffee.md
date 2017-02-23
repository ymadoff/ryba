
# WebHCat Stop

Run the command `./bin/ryba stop -m ryba/hive/webhcat` to stop the WebHCat
server using Ryba.

Stop the WebHCat server. You can also stop the server manually with one of the
following two commands:

```
service hive-webhcat-server stop
su -l hive -c "/usr/hdp/current/hive-webhcat/sbin/webhcat_server.sh stop"
```

The file storing the PID is "/var/run/webhcat/webhcat.pid".

    module.exports = header: 'WebHCat Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        header: 'Stop service'
        name: 'hive-webhcat-server'

## Stop Clean Logs

      @call
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
        handler: ->
          @system.execute
            cmd: 'rm /var/log/webhcat/webhcat-console*'
            code_skipped: 1
          @system.execute
            cmd: 'rm /var/log/webhcat/webhcat.log*'
            code_skipped: 1
