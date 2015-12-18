
# YARN NodeManager Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop Server

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-yarn-nodemanager stop
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop nodemanager"
```

The file storing the PID is "/var/run/hadoop-yarn/yarn/yarn-yarn-nodemanager.pid".

    module.exports.push header: 'YARN NM # Stop Server', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hadoop-yarn-nodemanager'
        if_exists: '/etc/init.d/hadoop-yarn-nodemanager'

    module.exports.push header: 'YARN NM # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      {clean_logs, yarn} = @config.ryba
      return unless clean_logs
      @execute
        cmd: 'rm #{yarn.log_dir}/*/*-nodemanager-*'
        code_skipped: 1
