
# YARN Timeline Server Start

Start the Yarn Application History Server. You can also start the server
manually with the following command:

```
service hadoop-yarn-timelineserver start
su -l yarn -c "/usr/hdp/current/hadoop-yarn-timelineserver/sbin/yarn-daemon.sh --config /etc/hadoop/conf start timelineserver"
```

The ATS requires HDFS to be operationnal or an exception is trown: 
"java.lang.IllegalArgumentException: java.net.UnknownHostException: {cluster name}".

    module.exports = header: 'YARN ATS Start', label_true: 'STARTED', handler: ->

## Wait

Wait for Kerberos and the HDFS NameNode.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'

## Run

Start the service.

      @service.start
        name: 'hadoop-yarn-timelineserver'
        if_exists: '/etc/init.d/hadoop-yarn-timelineserver'
