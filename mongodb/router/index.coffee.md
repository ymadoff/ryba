
# MongoDB Routing Server

MongoDB is a document-oriented database. Distributed Version

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      mongodb = ctx.config.ryba.mongodb ?= {}
      mongodb.router ?= {}
      # RoutingSrv Config
      config = mongodb.router.config ?= {}
      config.bind_ip ?= '0.0.0.0'
      config.fork ?= true
      config.port ?= 27017
      config.pidfilepath ?= '/var/run/mongodb/mongos.pid'
      config.logpath ?= '/var/log/mongodb/mongos.log'

## Commands

    module.exports.push commands: 'check', modules: 'ryba/mongodb/router/check'

    module.exports.push commands: 'install', modules: [
      'ryba/mongodb/router/install'
      # 'ryba/mongodb/router/start'
      # 'ryba/mongodb/router/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/mongodb/router/start'

    module.exports.push commands: 'stop', modules: 'ryba/mongodb/router/stop'

    module.exports.push commands: 'status', modules: 'ryba/mongodb/router/status'


