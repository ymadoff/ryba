
# Ganglia Monitor Stop

Execute this command on all the nodes in your Hadoop cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

## Stop

Stop the Ganglia Monitor server. You can also stop the server manually with
the following command:

```
service hdp-gmond stop
```

The files storing the PIDs are "/var/run/ganglia/hdp/HDPHBaseMaster/gmond.pid",
"/var/run/ganglia/hdp/HDPHistoryServer/gmond.pid",  "/var/run/ganglia/hdp/HDPNameNode/gmond.pid",
"/var/run/ganglia/hdp/HDPResourceManager/gmond.pid" and "/var/run/ganglia/hdp/HDPSlaves/gmond.pid".

    module.exports.push name: 'Ganglia Monitor # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'hdp-gmond'
        action: 'stop'
        if_exists: '/etc/init.d/hdp-gmond'
