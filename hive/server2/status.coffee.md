
# Hive Server2 Status

Check if the Hive Server2 is running. The process ID is located by default
inside "/var/run/hive/hive-server2.pid".

Exit code is "3" if server not runnig or "1" if server not running but pid file
still exists.

    module.exports = header: 'Hive Server2 Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hive-server2'
        code_stopped: [1, 3]
        if_exists: '/etc/init.d/hive-server2'
