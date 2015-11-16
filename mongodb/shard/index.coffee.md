
# MongoDB Shard (Distributed)

MongoDB is a document-oriented database. Distributed Version

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      mongodb = ctx.config.ryba.mongodb ?= {}
      # User
      mongodb.shard ?= {}
      # ShardSrv Config
      config = mongodb.shard.config ?= {}
      config.bind_ip ?= '0.0.0.0'
      config.fork ?= true
      config.port ?= 27017
      config.pidfilepath ?= '/var/run/mongodb/shard.pid'
      config.logpath ?= '/var/log/mongodb/mongod.log'
      config.dbpath ?= path.join mongodb.user.home, 'shard'
      config.journal ?= true
      config.smallfiles ?= true

    module.exports.push commands: 'check', modules: 'ryba/mongodb/shard/check'

    module.exports.push commands: 'install', modules: [
      'ryba/mongodb/shard/install'
      # 'ryba/mongodb/shard/start'
      # 'ryba/mongodb/shard/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/mongodb/shard/start'

    module.exports.push commands: 'stop', modules: 'ryba/mongodb/shard/stop'

    module.exports.push commands: 'status', modules: 'ryba/mongodb/shard/status'

## Dependencies

    path = require 'path'
