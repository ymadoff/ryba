
# Zookeeper Server Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push require('./server').configure

## Start ZooKeeper

Execute these commands on the ZooKeeper host machine(s).

    module.exports.push name: 'ZooKeeper Server # Start', label_true: 'STARTED', handler: (ctx, next) ->
      lifecycle.zookeeper_start ctx, next

