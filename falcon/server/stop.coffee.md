
# Falcon Server Stop

Stop the Falcon service. You can also stop the server manually with the
following command:

```
su -l falcon -c "/usr/hdp/current/falcon-server/bin/service-stop.sh falcon"
```

    module.exports = header: 'Falcon Server Stop', timeout: -1, label_true: 'STOPPED', handler: ->
      {clean_logs, falcon} = @config.ryba
      throw Error "Invalid log dir" unless falcon.log_dir

      @service.stop
        name: 'falcon'
        if_exists: '/etc/init.d/falcon'

## Clean Logs

      @execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> clean_logs
        cmd: "rm #{falcon.log_dir}/*"
        code_skipped: 1
