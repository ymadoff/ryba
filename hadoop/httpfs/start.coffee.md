
# HDFS HttpFS Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'

## Start

Start the HDFS HttpFS Server. You can also start the server
manually with the following command:

```
service hadoop-httpfs start
su -l httpfs -c '/usr/hdp/current/hadoop-httpfs/sbin/httpfs.sh start'
```

    module.exports.push header: 'HDFS HttpFS # Start', handler: ->
      @service_start
        name: 'hadoop-httpfs'
        if_exists: '/etc/init.d/hadoop-httpfs'
