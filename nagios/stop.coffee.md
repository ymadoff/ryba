
# Nagios Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Stop

Stop the Nagios server. The file storing the process ID (PID) is located in
"/var/run/nagios.pid". You can also stop the server manually with the following
command:

```
service nagios stop
```

The file storing the PID is "/var/run/nagios.pid".

    module.exports.push header: 'Nagios # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'nagios'
        code_stopped: 1

## Stop Clean Logs

    module.exports.push header: 'Nagios # Stop Clean Logs', label_true: 'CLEANED', handler: ->
      return unless @config.ryba.clean_logs
      @execute
        cmd: 'rm /var/log/nagios/*'
        code_skipped: 1
