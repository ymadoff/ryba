
# MongoDB Shard (Distributed)

MongoDB is a document-oriented database. Distributed Version

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('../').configure ctx
      mongodb = ctx.config.ryba.mongodb ?= {}
      # User
      mongodb.user = name: mongodb.user if typeof mongodb.user is 'string'
      mongodb.user ?= {}
      mongodb.user.name ?= 'mongodb'
      mongodb.user.system ?= true
      mongodb.user.comment ?= 'MongoDB User'
      mongodb.user.home ?= '/var/lib/mongodb'
      mongodb.user.groups ?= ['hadoop']
      # Group
      mongodb.group = name: mongodb.group if typeof mongodb.group is 'string'
      mongodb.group ?= {}
      mongodb.group.name ?= 'mongodb'
      mongodb.group.system ?= true
      mongodb.user.gid = mongodb.group.name
      # ConfigSrv Config
      config = mongodb.conf_config ?= {}
      config.bind_ip ?= '0.0.0.0'
      config.fork ?= true
      config.port ?= 27019
      config.pidfilepath ?= '/var/run/mongodb/config.pid'
      config.logpath ?= '/var/log/mongodb/mongod.log'
      config.dbpath ?= path.join mongodb.user.home, 'config'
      config.journal ?= true
      config.smallfiles ?= true
      # RoutingSrv Config
      config = mongodb.routing_config ?= {}
      config.bind_ip ?= '0.0.0.0'
      config.fork ?= true
      config.port ?= 27017
      config.pidfilepath ?= '/var/run/mongodb/mongos.pid'
      config.logpath ?= '/var/log/mongodb/mongod.log'
      config.configdb ?=
      # ShardSrv Config
      config = mongodb.shard_config ?= {}
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
