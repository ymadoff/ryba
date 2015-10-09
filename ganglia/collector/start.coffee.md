
# Ganglia Collector Start

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

# Start

The gmetad daemon is started by the "hdp-gmetad" script and not directly. The
"hdp-gemetad" will enter into an invalid state if "gmetad" is stoped
independently complaining that "rrdcached" is already running.

You can also start the server manually with the following command:

```
service hdp-gmetad start
```

    module.exports.push name: 'Ganglia Collector # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'hdp-gmetad'
        if_exists: '/etc/init.d/hdp-gmetad'
