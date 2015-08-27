
# Zookeeper Server Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Wait Listen

Wait for all ZooKeeper server to listen.

    module.exports.push name: 'ZooKeeper Server # Wait Listen', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      ctx.wait_connect
        servers: for zk_ctx in ctx.contexts 'ryba/zookeeper/server', require('./index').configure
          host: zk_ctx.config.host, port: zk_ctx.config.ryba.zookeeper.port
        quorum: true
      .then next
