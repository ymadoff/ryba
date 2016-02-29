
## Wait

    module.exports = header: 'MongoDB Config Server # Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/mongodb/configsrv', require('../configsrv').configure
          host: ctx.config.host
          port: ctx.config.ryba.mongodb.configsrv.config.net.port
