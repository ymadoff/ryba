
# Ganglia Collector Stop

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

## Stop

Stop the Ganglia Collector server. You can also stop the server manually with
the following command:

```
service hdp-gmetad stop
```

The files storing the PIDs are "/var/run/ganglia/hdp/gmetad.pid" and
"/var/run/ganglia/hdp/rrdcached.pid".

    module.exports.push name: 'Ganglia Collector # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hdp-gmetad'
        if_exists: '/etc/init.d/hdp-gmetad'
