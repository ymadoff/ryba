
# Zookeeper Server Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

Check if the ZooKeeper server is running. The process ID is located by default
inside "/var/run/zookeeper/zookeeper_server.pid".

    module.exports.push name: 'ZooKeeper Server # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: "service zookeeper-server status"
        code_skipped: 3
        if_exists: '/etc/init.d/zookeeper-server'
      .then next
