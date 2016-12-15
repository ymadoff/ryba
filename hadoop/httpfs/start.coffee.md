
# HDFS HttpFS Start

Start the HDFS HttpFS Server. You can also start the server
manually with the following command:

```
service hadoop-httpfs start
su -l httpfs -c '/usr/hdp/current/hadoop-httpfs/sbin/httpfs.sh start'
```

    module.exports = header: 'HDFS HttpFS Start', handler: ->
      @call 'masson/core/krb5_client/wait'
      @call 'ryba/hadoop/hdfs_nn/wait'
      @service.start
        name: 'hadoop-httpfs'
        if_exists: '/etc/init.d/hadoop-httpfs'
