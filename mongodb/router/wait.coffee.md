
# MongoDB Routing Server Wait

    module.exports = header: 'MongoDB Routing Server Wait', label_true: 'READY', timeout: -1, handler: ->
      mongodb_configsrvs = @contexts 'ryba/mongodb/configsrv'
      @connection.wait
        servers: for ctx in mongodb_configsrvs
          host: @config.host
          port: @config.ryba.mongodb.router.config.net.port
