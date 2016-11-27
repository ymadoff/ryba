
## Wait

    module.exports = header: 'MongoDB Shard Server Wait', label_true: 'READY', timeout: -1, handler: ->
      mongodb_shards = @contexts 'ryba/mongodb/shard'
      @connection.wait
        servers: for ctx in mongodb_shards
          host: ctx.config.host
          port: ctx.config.ryba.mongodb.shard.config.net.port
