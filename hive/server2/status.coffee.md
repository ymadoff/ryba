
# Hive Server2 Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

Check if the Hive Server2 is running. The process ID is located by default
inside "/var/run/hive/hive-server2.pid".

Exit code is "3" if server not runnig or "3" if server not running but pid file
still exists.

    module.exports.push header: 'Hive Server2 # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service hive-server2 status'
        code_skipped: [1, 3]
        if_exists: '/etc/init.d/hive-server2'
