
# Zookeeper Server Wait

Wait for all ZooKeeper server to listen.

    module.exports = header: 'ZooKeeper Server Wait', timeout: -1, label_true: 'READY', handler: ->
      servers = @contexts('ryba/zookeeper/server')
      .filter (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant'
      .map (ctx) -> host: ctx.config.host, port: ctx.config.ryba.zookeeper.port
      @connection.wait
        servers: servers
        quorum: true
