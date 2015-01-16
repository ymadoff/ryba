
# Zookeeper Server Wait

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./server').configure

## Wait Listen

Wait for all ZooKeeper server to listen.

    module.exports.push name: 'ZooKeeper Server # Wait Listen', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      zs_hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      wait = for zs_host in zs_hosts
        zs_ctx = ctx.hosts[zs_host]
        require('./server').configure zs_ctx
        host: zs_host, port: zs_ctx.config.ryba.zookeeper.port
      ctx.waitIsOpen wait, (err) -> next err




