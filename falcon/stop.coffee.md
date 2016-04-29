
# Falcon Stop

Stop the Falcon service. You can also stop the server manually with the
following command:

```
su -l falcon -c "/usr/hdp/current/falcon-server/bin/service-stop.sh falcon"
```

    module.exports = header: 'Falcon Stop Service', timeout: -1, label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'falcon'
        if_exists: '/etc/init.d/falcon'

## Stop Clean Logs

      @call header: 'Falcon Stop Clean Logs', skip: true, timeout: -1, label_true: 'TODO', handler: ->
      # TODO
