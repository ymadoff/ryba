
# Hadoop YARN ResourceManager Start

Start the ResourceManager server. You can also start the server manually with the
following two commands:

```
service hadoop-yarn-resourcemanager start
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start resourcemanager"
```

    module.exports = header: 'YARN RM Start', label_true: 'STARTED', retry: 3, handler: (options) ->
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

      @remove
        target: "#{yarn.pid_dir}/yarn-#{yarn.user.name}-resourcemanager.pid"
        if: options.attempt > 0

## Run

Start the service.

      @service.start
        name: 'hadoop-yarn-resourcemanager'
