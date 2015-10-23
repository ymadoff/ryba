
# MongoDB Routing Server Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait

    module.exports.push name: 'MongoDB Routing Server # Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/mongodb/router'
          host: ctx.config.host
          port: ctx.config.ryba.mongodb.srv_config.port