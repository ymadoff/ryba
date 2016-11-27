
## Wait

    module.exports = header: 'MongoDB Config Server Wait', label_true: 'READY', timeout: -1, handler: ->
      mongodb_configsrvs = @contexts 'ryba/mongodb/configsrv'
      @connection.wait
        servers: for ctx in mongodb_configsrvs
          host: ctx.config.host
          port: ctx.config.ryba.mongodb.configsrv.config.net.port
