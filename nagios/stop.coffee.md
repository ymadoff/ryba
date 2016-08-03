
# Nagios Stop

    module.exports = header: 'Nagios Stop', label_true: 'STOPPED', handler: ->

## Stop

Stop the Nagios server. The file storing the process ID (PID) is located in
"/var/run/nagios.pid". You can also stop the server manually with the following
command:

```
service nagios stop
```

The file storing the PID is "/var/run/nagios.pid".

      @service_stop
        name: 'nagios'
        code_stopped: 1

## Stop Clean Logs

      @execute
        header: Clean Logs
        cmd: 'rm /var/log/nagios/*'
        code_skipped: 1
        if: @config.ryba.clean_logs
