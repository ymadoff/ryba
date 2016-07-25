
# YARN NodeManager Stop

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-yarn-nodemanager stop
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop nodemanager"
```

The file storing the PID is "/var/run/hadoop-yarn/yarn/yarn-yarn-nodemanager.pid".

    module.exports = header: 'YARN NM Stop', label_true: 'STOPPED', handler: ->
      {clean_logs, yarn} = @config.ryba

      @service_stop
        header: 'YARN NM Stop'
        label_true: 'STOPPED'
        name: 'hadoop-yarn-nodemanager'
        if_exists: '/etc/init.d/hadoop-yarn-nodemanager'

      @execute
        header: 'YARN NM Clean Logs'
        if: clean_logs
        cmd: 'rm #{yarn.log_dir}/*/*-nodemanager-*'
        code_skipped: 1
