
# Zookeeper Server Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

Check if the ZooKeeper server is running. The process ID is located by default
inside "/var/run/zookeeper/zookeeper_server.pid".

    module.exports.push header: 'ZooKeeper Server # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service zookeeper-server status'
        code_skipped: 1 # Exit code is 1 while convention is 3
        if_exists: '/etc/init.d/zookeeper-server'
