
# HDFS HttpFS Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Stop

Stop the HDFS HttpFS service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-httpfs start
su -l httpfs -c '/usr/hdp/current/hadoop-httpfs/sbin/httpfs.sh stop'
```

    module.exports.push name: 'HDFS HttpFS # Stop Server', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hadoop-httpfs'
        if_exists: '/etc/init.d/hadoop-httpfs'

    # module.exports.push name: 'YARN TS # Stop Clean Logs', label_true: 'CLEANED', handler: ->
    #   {clean_logs, yarn} = @config.ryba
    #   return next() unless clean_logs
    #   @execute
    #     cmd: 'rm #{yarn.log_dir}/*/*-nodemanager-*'
    #     code_skipped: 1
