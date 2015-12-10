
# YARN Timeline Server Start

The ATS requires HDFS to be operationnal or an exception is trown: 
"java.lang.IllegalArgumentException: java.net.UnknownHostException: {cluster name}".

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push 'ryba/hadoop/hdfs_nn/wait'

## Start

Start the Yarn Application History Server. You can also start the server
manually with the following command:

```
service hadoop-yarn-timelineserver start
su -l yarn -c "/usr/hdp/current/hadoop-yarn-timelineserver/sbin/yarn-daemon.sh --config /etc/hadoop/conf start timelineserver"
```

    module.exports.push header: 'YARN ATS # Start', handler: ->
      @service_start
        name: 'hadoop-yarn-timelineserver'
        if_exists: '/etc/init.d/hadoop-yarn-timelineserver'
