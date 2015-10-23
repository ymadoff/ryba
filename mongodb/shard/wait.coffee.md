
# MongoDB Shard Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'MongoDB Shard # Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/mongodb/shard'
          host: ctx.config.host
          port: ctx.config.ryba.mongodb.shard.config.port