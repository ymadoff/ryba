
# MongoDB Routing Server Wait

    module.exports.push = header: 'MongoDB Routing Server # Wait', label_true: 'READY', timeout: -1, handler: ->

## Wait

      @wait_connect
        servers: for ctx in @contexts 'ryba/mongodb/router'
          host: @config.host
          port: @config.ryba.mongodb.router.config.net.port
