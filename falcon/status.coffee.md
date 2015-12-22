
# Falcon Status

Run the command `su -l falcon -c '/usr/lib/falcon/bin/falcon-status'` to
retrieve the status of the Falcon server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status Service

Discover the server status.

```
su -l falcon -c '/usr/hdp/current/falcon-server/bin/service-status.sh falcon'; [ $? -eq 254 ]
```

    module.exports.push header: 'Falcon # Status Service', timeout: -1, label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status 
        name: 'falcon'
        code_skipped: [1, 3]
        if_exists: '/etc/init.d/falcon'
