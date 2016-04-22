
# Hadoop YARN ResourceManager Start

Start the ResourceManager server. You can also start the server manually with the
following two commands:

```
service hadoop-yarn-resourcemanager start
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start resourcemanager"
```

    module.exports = header: 'Yarn RM Start', label_true: 'STARTED', handler: ->
      {yarn} = @config.ryba

## Wait

Wait for Kerberos, Zookeeper, HFDS, YARN and the MapReduce History Server. The
History Server must be started because the ResourceManager will try to load
the history of MR jobs from there.

      @call once: true, 'masson/core/krb5_client/wait'
      @call once: true, 'ryba/zookeeper/server/wait'
      @call once: true, 'ryba/hadoop/hdfs_dn/wait'
      @call once: true, 'ryba/hadoop/yarn_ts/wait'
      @call once: true, 'ryba/hadoop/mapred_jhs/wait'

## Cleanup

Ensure the service pid is removed on retry.

TODO: retry is temporary disable
TODO: seems like removing the pid is no longer required after the rewrite of the
startup script.s

      @remove
        destination: "#{yarn.pid_dir}/yarn-#{yarn.user.name}-resourcemanager.pid"
        if: @retry > 0

## Run

Start the service.

      @service_start
        name: 'hadoop-yarn-resourcemanager'
        if_exists: '/etc/init.d/hadoop-yarn-resourcemanager'
