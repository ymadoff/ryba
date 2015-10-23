
# MongoDB Config Server (Distributed)

MongoDB is a document-oriented database. Distributed Version.

Config servers are special mongod instances that store the metadata for a 
sharded cluster.
A production sharded cluster has EXACTLY THREE config servers. 
All config servers must be available to deploy a sharded cluster or to make any 
changes to cluster metadata. Config servers do not run as replica sets.

    module.exports = []
    module.exports.push 'ryba/mongodb'

## Configure

    module.exports.configure = (ctx) ->
      ctx.config.ryba.mongodb ?= {}
      configsrv = ctx.config.ryba.mongodb.configsrv ?= {}
      config = configsrv.config ?= {}
      config.port ?= 27019
      config.bind_ip ?= '0.0.0.0'
      config.fork ?= true
      config.logpath ?= '/var/log/mongodb/mongod-configsrv.log'
      config.dbpath ?= '/var/lib/mongodb/config'
      config.journal ?= true
      config.smallfiles ?= true

## Commands

    module.exports.push commands: 'check', modules: 'ryba/mongodb/configsrv/check'

    module.exports.push commands: 'install', modules: [
      'ryba/mongodb/configsrv/install'
      # 'ryba/mongodb/configsrv/start'
      # 'ryba/mongodb/configsrv/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/mongodb/configsrv/start'

    module.exports.push commands: 'stop', modules: 'ryba/mongodb/configsrv/stop'

    module.exports.push commands: 'status', modules: 'ryba/mongodb/configsrv/status'

## Dependencies

    path = require 'path'
