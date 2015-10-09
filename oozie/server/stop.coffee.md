
# Oozie Server Stop

Run the command `./bin/ryba stop -m ryba/oozie/server` to stop the Oozie
server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the Oozie service. You can also stop the server manually with the
following command:

```
service stop oozie
su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozied.sh stop"
```

The file storing the PID is "/var/run/oozie/oozie.pid".

    module.exports.push name: 'Oozie Server # Stop', label_true: 'STOPPED', timeout: -1, handler: ->
      {oozie} = @config.ryba
      @service_stop
        name: 'oozie'

## Stop Clean Logs

    module.exports.push
      name: 'Oozie Server # Stop Clean Logs'
      label_true: 'CLEANED'
      if: -> @config.ryba.clean_logs
      handler: ->
        @execute
          cmd: 'rm /var/log/oozie/*'
          code_skipped: 1
