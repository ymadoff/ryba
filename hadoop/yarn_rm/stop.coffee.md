
# Hadoop YARN ResourceManager Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hadoop-yarn-resourcemanager stop
su -l yarn -c "/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop resourcemanager"
```

The file storing the PID is "/var/run/hadoop-yarn/yarn/yarn-yarn-resourcemanager.pid".

    module.exports.push name: 'Yarn RM # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'hadoop-yarn-resourcemanager'
        action: 'stop'
        if_exists: '/etc/init.d/hadoop-yarn-resourcemanager'

    module.exports.push name: 'Yarn RM # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      {clean_logs, yarn} = @config.ryba
      return next() unless clean_logs
      @execute
        cmd: 'rm #{yarn.log_dir}/*/*-resourcemanager-*'
        code_skipped: 1
