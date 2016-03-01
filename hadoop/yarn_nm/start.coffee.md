
# YARN NodeManager Start

Start the Yarn NodeManager service. You can also start the server manually with the
following two commands:

```
service hadoop-yarn-nodemanager start
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && /usr/hdp/current/hadoop-yarn-nodemanager/sbin/yarn-daemon.sh --config /etc/hadoop-yarn-resourcemanager/conf start nodemanager"
```

    module.exports = header: 'YARN NM # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'hadoop-yarn-nodemanager'
