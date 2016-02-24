
# MongoDB Config Server (Distributed)

MongoDB is a document-oriented database. Distributed Version.

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
      shardsrv_ctxs = ctx.contexts 'ryba/mongodb/shard', require('../shard').configure
      throw new Error 'No mongo shards server configured ' unless shardsrv_ctxs.length > 0
      throw new Error 'No mongo routers configured (mongos)' unless ctx.hosts_with_module('ryba/mongodb/router').length > 0
      throw new Error 'No mongo shell configured ' unless ctx.hosts_with_module('ryba/mongodb/client').length > 0
      # Config
      mongodb.configsrv ?= {}
      mongodb.configsrv.conf_dir ?= '/etc/mongodb-config-server/conf'
      mongodb.configsrv.pid_dir ?= '/var/run/mongodb'

      #mongo admin user
      mongodb.admin ?= {}
      mongodb.admin.name ?= 'admin'
      mongodb.admin.password ?= 'admin123'
      mongodb.root ?= {}
      mongodb.root.name ?= 'root_admin'
      mongodb.root.password ?= 'root123'
      config = mongodb.configsrv.config ?= {}
      # setting the role of mongod process as a mongodb config server
      config.sharding ?= {}
      config.sharding.clusterRole ?= 'configsvr'

## Logs

      config.systemLog ?= {}
      config.systemLog.destination ?= 'file'
      config.systemLog.logAppend ?= true
      config.systemLog.path ?= "/var/log/mongodb/mongod-config-server-#{ctx.config.host}.log"

## Storage

From 3.2, config servers for sharded clusters can be deployed as a replica set.
The replica set config servers must run the WiredTiger storage engine

      config.storage ?= {}
      config.storage.dbPath ?= '/var/lib/mongodb/configsrv/db'
      config.storage.repairPath ?= "#{config.storage.dbPath}/repair"
      config.storage.journal ?= {}
      config.storage.journal.enabled ?= true
      if config.storage.repairPath.indexOf(config.storage.dbPath) is -1
        throw Error 'Must use a repairpath that is a subdirectory of dbpath when using journaling' if config.storage.journal.enabled
      config.storage.engine ?= 'wiredTiger'
      throw Error 'Need WiredTiger Storage for config server as replica set' unless config.storage.engine is 'wiredTiger'

## Replica Set Sharding Discovery

Deploys config server as replica set. You can configure a custom layout by giving
an object containing a list of replica set  name and the associated hosts.
By default Ryba deploys only one replica set for all the config server.

Ryba check also mapping between config server and Shard Cluster
Indeed Each Shard Cluster must be attributed to only one Config server replica set.
So in the configuration, the administrator must attribute to a config server replica set
the list of Shard Cluster for whose it stores the metadata.

By default config servers replica set layout is not defined (`mongodb.configsrv.replica_sets`)
ryba use all the config server available to create a replica set of config server, and
all the Shard Cluster available are attributed to the config server replica set.

Of course if no shard Cluster is configured, ryba uses all available Sharding server to create
one replica set Shard Cluster. That's why we need the `ryba/mongodb/shard` module to be configured before
`ryba/mongodb/configsrv` module.


      shards_replica_sets = shardsrv_ctxs[0].config.ryba.mongodb.shard.replica_sets
      config.replication ?= {}
      mongodb.configsrv.replica_sets ?=
        configsrvRepSet1:
          hosts: ctx.hosts_with_module ('ryba/mongodb/configsrv')
          shards: Object.keys(shards_replica_sets)
      # we  check if every config server is maped to one and only one config  replica set name.
      replSets = Object.keys(mongodb.configsrv.replica_sets)
      throw Error 'No replica sets found for config servers' unless replSets.length > 0
      checkMapping = 0
      for replSet, layout of mongodb.configsrv.replica_sets
        throw Error "no hosts defined for config replica set #{replSet}" unless layout.hosts.length? > 0
        for host in layout.hosts
          if host is ctx.config.host
            config.replication.replSetName ?= "#{replSet}"
            checkMapping++
            throw Error 'can attribute one config server to only one replica set' if checkMapping > 1
      throw Error 'No replica set configured for config server ', ctx.config.host unless config.replication.replSetName
      # now we are sure that the host belong to one and only one replica set
      # getting back the replica master for our replica set
      for host in mongodb.configsrv.replica_sets[config.replication.replSetName].hosts
        mongodb.configsrv.replica_master ?= host if ctx.context(host).config.ryba.mongo_config_replica_master?
      throw Error ' No master configured for replica set' unless mongodb.configsrv.replica_master?
      mongodb.configsrv.is_master ?= if mongodb.configsrv.replica_master is ctx.config.host then true else false
      # now the host knows which server is the replica primary server and know if its him.
      # we  check if shard Cluster is not attributed to different config replica set
      checkShards = {}
      for replSet, layout of mongodb.configsrv.replica_sets
        for shard in layout.shards
          checkShards[shard] =  if checkShards[shard]? then checkShards + 1 else  1
          throw Error "Shard Cluster #{shard} must belong to only one config server replica set" if checkShards[shard] > 1
          throw Error "Unknown Shard Cluster name #{shard}" unless Object.keys(shards_replica_sets).indexOf(shard) > -1



## Process

      config.processManagement ?= {}
      config.processManagement.fork ?= true
      config.processManagement.pidFilePath ?= "#{mongodb.configsrv.pid_dir}/mongod-config-server-#{ctx.config.host}.pid"

## Network

[Configuring][mongod-ssl] ssl for the mongod process.

      config.net ?= {}
      config.net.port ?=  27017
      config.net.bindIp ?=  '0.0.0.0'

## Security

      # disables the apis
      config.net.http ?=  {}
      config.net.http.enabled ?= false
      config.net.http.JSONPEnabled ?= false
      config.net.http.RESTInterfaceEnabled ?= false
      config.net.unixDomainSocket ?= {}
      config.net.unixDomainSocket.pathPrefix ?= '/tmp/mongod-config-server'
      config.security ?= {}
      config.security.clusterAuthMode ?= 'x509'

## SSL

      switch config.security.clusterAuthMode
        when 'x509'
          config.net.ssl ?= {}
          config.net.ssl.mode ?= 'preferSSL'
          config.net.ssl.PEMKeyFile ?= "#{mongodb.configsrv.conf_dir}/key.pem"
          config.net.ssl.PEMKeyPassword ?= "mongodb123"
          # use PEMkeyfile by default for membership authentication
          # config.net.ssl.clusterFile ?= "#{mongodb.configsrv.conf_dir}/cluster.pem" # this is the mongodb version of java trustore
          # config.net.ssl.clusterPassword ?= "mongodb123"
          config.net.ssl.CAFile ?=  "#{mongodb.configsrv.conf_dir}/cacert.pem"
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
      mongodb.configsrv.sasl_password  ?= 'mongodb123'



## Commands

    module.exports.push commands: 'check', modules: [
      'masson/bootstrap'
      'ryba/mongodb/configsrv/check'
    ]

    module.exports.push commands: 'install', modules: [
      'masson/bootstrap'
      'masson/core/locale'
      'masson/core/yum'
      'masson/core/iptables'
      'ryba/mongodb/configsrv/install'
      'ryba/mongodb/configsrv/start'
      'ryba/mongodb/configsrv/wait'
      'ryba/mongodb/configsrv/replication'
      'ryba/mongodb/configsrv/check'
    ]

    module.exports.push commands: 'start', modules: [
      'masson/bootstrap'
      'ryba/mongodb/configsrv/start'
    ]

    module.exports.push commands: 'stop', modules: [
      'masson/bootstrap'
      'ryba/mongodb/configsrv/stop'
    ]

    module.exports.push commands: 'status', modules: [
      'masson/bootstrap'
      'ryba/mongodb/configsrv/status'
    ]
## Dependencies

    path = require 'path'

[mongod-ssl]:(https://docs.mongodb.org/manual/reference/configuration-options/#net.ssl.mode)
