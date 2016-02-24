
# MongoDB Shard (Distributed)

MongoDB is a document-oriented database. Distributed Version


Config servers are special mongod instances that store the metadata for a
sharded cluster.
All config servers must be available to deploy a sharded cluster or to make any
changes to cluster metadata.

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
      mongodb.user.limits ?= {}
      mongodb.user.limits.nofile ?= 64000
      mongodb.user.limits.nproc ?= true
      mongodb.user.gid = mongodb.group.name
      throw new Error 'No mongo routers configured (mongos)' unless ctx.hosts_with_module('ryba/mongodb/router').length > 0
      throw new Error 'No mongo shell configured ' unless ctx.hosts_with_module('ryba/mongodb/client').length > 0
      # Config
      mongodb.shard ?= {}
      mongodb.shard.conf_dir ?= '/etc/mongodb-shard-server/conf'
      mongodb.shard.pid_dir ?= '/var/run/mongodb'
      #mongo admin user for mongod instances belonging to a replica set
      mongodb.admin ?= {}
      mongodb.admin.name ?= 'admin'
      mongodb.admin.password ?= 'admin123'
      mongodb.root ?= {}
      mongodb.root.name ?= 'root_admin'
      mongodb.root.password ?= 'root123'
      config = mongodb.shard.config ?= {}
      # setting the role of mongod process as a mongodb config server
      config.sharding ?= {}
      config.sharding.clusterRole ?= 'shardsvr'

## Logs

      config.systemLog ?= {}
      config.systemLog.destination ?= 'file'
      config.systemLog.logAppend ?= true
      config.systemLog.path ?= "/var/log/mongodb/mongod-shard-server-#{ctx.config.host}.log"

## Storage

From 3.2, config servers for sharded clusters can be deployed as a replica set.
The replica set config servers must run the WiredTiger storage engine

      config.storage ?= {}
      config.storage.dbPath ?= '/var/lib/mongodb/shard/db'
      config.storage.repairPath ?= "#{config.storage.dbPath}/repair"
      config.storage.journal ?= {}
      config.storage.journal.enabled ?= true
      if config.storage.repairPath.indexOf(config.storage.dbPath) is -1
        throw Error 'Must use a repairpath that is a subdirectory of dbpath when using journaling' if config.storage.journal.enabled
      config.storage.engine ?= 'wiredTiger'
      throw Error 'Need WiredTiger Storage for shard server as replica set' unless config.storage.engine is 'wiredTiger'

## Replica Set Sharding

Deploys shard server as replica set. You can configure a custom layout by giving
an object containing a list of replica set  name and the associated hosts.
By default Ryba deploys only one replica set for all the config server.

      config.replication ?= {}
      mongodb.shard.replica_sets ?=  shardsrvRepSet1: ctx.hosts_with_module ('ryba/mongodb/shard')
      replSets = Object.keys(mongodb.shard.replica_sets)
      # we  check if every config server is maped to one and only one replica set.
      throw Error 'No replica sets found for shard server' unless replSets.length > 0
      checkMapping = 0
      for replSet, hosts of mongodb.shard.replica_sets
        for host in hosts
          if host is ctx.config.host
            config.replication.replSetName ?= "#{replSet}"
            checkMapping++
            throw Error 'can attribute one shard server to only one replica set' if checkMapping > 1
      throw Error 'No replica set configured for shard server ', ctx.config.host unless config.replication.replSetName
      # now we are sure that the host belong to one and only one replica set
      # getting back the replica master for our replica set
      for host in mongodb.shard.replica_sets[config.replication.replSetName]
        mongodb.shard.replica_master ?= host if ctx.context(host).config.ryba.mongo_shard_replica_master?
      throw Error ' No primary sharding server  configured for replica set' unless mongodb.shard.replica_master?
      mongodb.shard.is_master ?= if mongodb.shard.replica_master is ctx.config.host then true else false
      # now the host knows which server is the replica master and know if its him.

## Process

      config.processManagement ?= {}
      config.processManagement.fork ?= true
      config.processManagement.pidFilePath ?= "#{mongodb.shard.pid_dir}/mongod-shard-server-#{ctx.config.host}.pid"

## Network

[Configuring][mongod-ssl] ssl for the mongod process.

      config.net ?= {}
      config.net.port ?=  27019
      config.net.bindIp ?=  '0.0.0.0'
      config.net.unixDomainSocket ?= {}
      config.net.unixDomainSocket.pathPrefix ?= '/tmp/mongod-config-server'

## Security

      # disables the apis
      config.net.http ?=  {}
      config.net.http.enabled ?= false
      config.net.http.JSONPEnabled ?= false
      config.net.http.RESTInterfaceEnabled ?= false
      config.security ?= {}
      config.security.clusterAuthMode ?= 'x509'

## SSL

      switch config.security.clusterAuthMode
        when 'x509'
          config.net.ssl ?= {}
          config.net.ssl.mode ?= 'preferSSL'
          config.net.ssl.PEMKeyFile ?= "#{mongodb.shard.conf_dir}/key.pem"
          config.net.ssl.PEMKeyPassword ?= "mongodb123"
          # use PEMkeyfile by default for membership authentication
          # config.net.ssl.clusterFile ?= "#{mongodb.configsrv.conf_dir}/cluster.pem" # this is the mongodb version of java trustore
          # config.net.ssl.clusterPassword ?= "mongodb123"
          config.net.ssl.CAFile ?=  "#{mongodb.shard.conf_dir}/cacert.pem"
          config.net.ssl.allowConnectionsWithoutCertificates ?= false
          config.net.ssl.allowInvalidCertificates ?= false
          config.net.ssl.allowInvalidHostnames ?= false
        when 'keyFile'
          mongodb.sharedsecret ?= 'sharedSecretForMongodbCluster'
        else
          throw Error ' unsupported cluster authentication Mode'

## ACL's

      config.security.authorization ?= 'enabled'

## Kerberos

      config.security.sasl ?= {}
      config.security.sasl.hostName ?= ctx.config.host
      config.security.sasl.serviceName ?= 'mongodb' # Can override only on interprise edition
      mongodb.shard.sasl_password  ?= 'mongodb123'



## Commands

    module.exports.push commands: 'check', modules: 'ryba/mongodb/shard/check'

    module.exports.push commands: 'install', modules: [
      'masson/bootstrap'
      'masson/core/yum'
      'masson/core/locale'
      'masson/core/iptables'
      'masson/core/locale'
      'ryba/mongodb/shard/install'
      'ryba/mongodb/shard/start'
      'ryba/mongodb/shard/wait'
      'ryba/mongodb/shard/replication'
      'ryba/mongodb/shard/check'
    ]

    module.exports.push commands: 'start', modules: [
      'masson/bootstrap'
      'ryba/mongodb/shard/start'
    ]


    module.exports.push commands: 'stop', modules:  [
      'masson/bootstrap'
      'ryba/mongodb/shard/stop'
    ]

    module.exports.push commands: 'status', modules:  [
      'masson/bootstrap'
      'ryba/mongodb/shard/status'
    ]


## Dependencies

    path = require 'path'

[mongod-ssl]:(https://docs.mongodb.org/manual/reference/configuration-options/#net.ssl.mode)
