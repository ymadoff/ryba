
# YARN NodeManager Start

Start the Yarn NodeManager service. You can also start the server manually with the
following two commands:

```
service hadoop-yarn-nodemanager start
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && /usr/hdp/current/hadoop-yarn-nodemanager/sbin/yarn-daemon.sh --config /etc/hadoop-yarn-resourcemanager/conf start nodemanager"
```

    module.exports = header: 'YARN NM Start', label_true: 'STARTED', handler: ->

Wait for Kerberos, ZooKeeper and HDFS to be started.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait'

Start the service.

      @service.start name: 'hadoop-yarn-nodemanager'
