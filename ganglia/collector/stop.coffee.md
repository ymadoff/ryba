
# Ganglia Collector Stop

Stop the Ganglia Collector server. You can also stop the server manually with
the following command:

```
service hdp-gmetad stop
```

The files storing the PIDs are "/var/run/ganglia/hdp/gmetad.pid" and
"/var/run/ganglia/hdp/rrdcached.pid".

    module.exports = header: 'Ganglia Collector # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hdp-gmetad'
        code_stopped: 1
        if_exists: '/etc/init.d/hdp-gmetad'
