
# Falcon Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop Service

Stop the Falcon service. You can also stop the server manually with the
following command:

```
su -l falcon -c "/usr/hdp/current/falcon-server/bin/service-stop.sh falcon"
```

    module.exports.push header: 'Falcon # Stop Service', timeout: -1, label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'falcon'

## Stop Clean Logs

    module.exports.push header: 'Falcon # Stop Clean Logs', skip: true, timeout: -1, label_true: 'TODO', handler: ->
      # TODO
