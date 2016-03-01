
# Zookeeper Server Wait

Wait for all ZooKeeper server to listen.

    module.exports = header: 'ZooKeeper Server Wait', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for zk_ctx in @contexts 'ryba/zookeeper/server'
          host: zk_ctx.config.host, port: zk_ctx.config.ryba.zookeeper.port
        quorum: true
