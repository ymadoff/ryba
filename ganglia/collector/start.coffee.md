
# Ganglia Collector Start

The gmetad daemon is started by the "hdp-gmetad" script and not directly. The
"hdp-gemetad" will enter into an invalid state if "gmetad" is stoped
independently complaining that "rrdcached" is already running.

You can also start the server manually with the following command:

```
service hdp-gmetad start
```

    module.exports = header: 'Ganglia Collector # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'hdp-gmetad'
        code_stopped: 1
