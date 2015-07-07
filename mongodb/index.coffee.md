
# Mongo DB

MongoDB is a document-oriented database. It can be instanciated in standalone or
sharded (distributed) mode.
This file contains shared Configuration.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      mongodb = ctx.config.ryba.mongodb ?= {}
      # User
      mongodb.user = name: mongodb.user if typeof mongodb.user is 'string'
      mongodb.user ?= {}
      mongodb.user.name ?= 'mongod'
      mongodb.user.system ?= true
      mongodb.user.comment ?= 'MongoDB User'
      mongodb.user.home ?= '/var/lib/mongo'
      # Group
      mongodb.group = name: mongodb.group if typeof mongodb.group is 'string'
      mongodb.group ?= {}
      mongodb.group.name ?= 'mongod'
      mongodb.group.system ?= true
      mongodb.user.gid = mongodb.group.name
      # Config
      config = mongodb.srv_config ?= {}
      config.bind_ip ?= '0.0.0.0'
      config.fork ?= true
      config.port ?= 27017
      config.pidfilepath ?= '/var/run/mongodb/mongod.pid'
      config.logpath ?= '/var/log/mongodb/mongod.log'
      config.dbpath ?= path.join mongodb.user.home, 'server'
      config.journal ?= true
      config.smallfiles ?= true

    module.exports.push commands: 'check', modules: 'ryba/mongodb/check'

    module.exports.push commands: 'install', modules: [
      'ryba/mongodb/install'
      'ryba/mongodb/start'
      'ryba/mongodb/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/mongodb/start'

    module.exports.push commands: 'stop', modules: 'ryba/mongodb/stop'

    module.exports.push commands: 'status', modules: 'ryba/mongodb/status'

## Module Dependencies

    path = require 'path'
