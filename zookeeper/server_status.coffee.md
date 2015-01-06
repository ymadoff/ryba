
# Zookeeper Server Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

Discover the server status.

    module.exports.push name: 'ZooKeeper Server # Status', label_true: 'STARTED', label_false: 'STOPPED', callback: (ctx, next) ->
      ctx.execute
        cmd: "service zookeeper-server status"
        code_skipped: 3
        if_exists: '/etc/init.d/zookeeper-server'
      , next
