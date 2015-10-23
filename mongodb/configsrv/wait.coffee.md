
# MongoDB Config Server Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Wait

    module.exports.push name: 'MongoDB ConfigSrv # Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/mongodb/configsrv'
          host: ctx.config.host
          port: ctx.config.ryba.mongodb.configsrv.config.port