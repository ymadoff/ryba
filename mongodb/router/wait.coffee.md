
# MongoDB Routing Server Wait

    module.exports = header: 'MongoDB Routing Server Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for ctx in @contexts 'ryba/mongodb/router'
          host: @config.host
          port: @config.ryba.mongodb.router.config.net.port
