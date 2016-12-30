
# Hadoop YARN ResourceManager Stop

    module.exports = header: 'YARN RM Stop', label_true: 'STOPPED', handler: ->
      {clean_logs, yarn} = @config.ryba

## Stop

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hadoop-yarn-resourcemanager stop
su -l yarn -c "/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop resourcemanager"
```

The file storing the PID is "/var/run/hadoop-yarn/yarn/yarn-yarn-resourcemanager.pid".

      @service.stop
        header: 'Stop service'
        label_true: 'STOPPED'
        name: 'hadoop-yarn-resourcemanager'

      @execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: clean_logs
        cmd: 'rm #{yarn.log_dir}/*/*-resourcemanager-*'
        code_skipped: 1
