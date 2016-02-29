
## Wait

    module.exports = header: 'MongoDB Shard Server # Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/mongodb/shard', require('../shard').configure
          host: ctx.config.host
          port: ctx.config.ryba.mongodb.shard.config.net.port
