
# HDFS HttpFS Stop

Stop the HDFS HttpFS service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-httpfs start
su -l httpfs -c '/usr/hdp/current/hadoop-httpfs/sbin/httpfs.sh stop'
```

    module.exports = header: 'HDFS HttpFS # Stop Server', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'hadoop-httpfs'
        if_exists: '/etc/init.d/hadoop-httpfs'

    # module.exports.push header: 'YARN TS # Stop Clean Logs', label_true: 'CLEANED', handler: ->
    #   {clean_logs, yarn} = @config.ryba
    #   return unless clean_logs
    #   @execute
    #     cmd: 'rm #{yarn.log_dir}/*/*-nodemanager-*'
    #     code_skipped: 1
