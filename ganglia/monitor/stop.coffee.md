
# Ganglia Monitor Stop

Execute this command on all the nodes in your Hadoop cluster.


## Stop

Stop the Ganglia Monitor server. You can also stop the server manually with
the following command:

```
service hdp-gmond stop
```

The files storing the PIDs are "/var/run/ganglia/hdp/HDPHBaseMaster/gmond.pid",
"/var/run/ganglia/hdp/HDPHistoryServer/gmond.pid",  "/var/run/ganglia/hdp/HDPNameNode/gmond.pid",
"/var/run/ganglia/hdp/HDPResourceManager/gmond.pid" and "/var/run/ganglia/hdp/HDPSlaves/gmond.pid".

    module.exports = header: 'Ganglia Monitor Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        header: 'Stop service'
        name: 'hdp-gmond'
        code_stopped: 1
        if_exists: '/etc/init.d/hdp-gmond'
