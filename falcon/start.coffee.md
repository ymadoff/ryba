
# Falcon Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    # module.exports.push require('./index').configure

## Start

Start the Falcon server. You can also start the server manually with the
following command:

```
su -l falcon -c "/usr/hdp/current/falcon-server/bin/service-start.sh falcon"
```

    module.exports.push header: 'Falcon # Start Service', timeout: -1, label_true: 'STARTED', handler: ->
      @service_start
        name: 'falcon'
