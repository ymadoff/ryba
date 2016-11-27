
## Configure

    module.exports = ->
      mongodb_configsrvs = @contexts 'ryba/mongodb/configsrv'
      mongodb_shards = @contexts 'ryba/mongodb/shard'
      mongodb = @config.ryba.mongodb ?= {}
      # User
      mongodb.user = name: mongodb.user if typeof mongodb.user is 'string'
      mongodb.user ?= {}
      mongodb.user.name ?= 'mongodb'
      mongodb.user.system ?= true
      mongodb.user.comment ?= 'MongoDB User'
      mongodb.user.home ?= '/var/lib/mongodb'
      # Group
      mongodb.group = name: mongodb.group if typeof mongodb.group is 'string'
      mongodb.group ?= {}
      mongodb.group.name ?= 'mongodb'
      mongodb.group.system ?= true
      mongodb.user.limits ?= {}
      mongodb.user.limits.nofile ?= 64000
      mongodb.user.limits.nproc ?= true
      mongodb.user.gid = mongodb.group.name
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
      config.systemLog.path ?= "/var/log/mongodb/mongod-shard-server-#{@config.host}.log"

## Storage

From 3.2, config servers for sharded clusters can be deployed as a replica set.
The replica set config servers must run the WiredTiger storage engine

      config.storage ?= {}
      config.storage.dbPath ?= "#{mongodb.user.home}/shard/db"
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
By default Ryba deploys only one replica set for all the shard servers.

      config.replication ?= {}
      mongodb.shard.replica_sets ?=  shardsrvRepSet1: 
        hosts: mongodb_shards.map( (ctx)-> ctx.config.host)
      replSets = Object.keys(mongodb.shard.replica_sets)
      # we  check if every config server is maped to one and only one replica set.
      throw Error 'No replica sets found for shard server' unless replSets.length > 0
      checkMapping = 0
      for replSet, layout of mongodb.shard.replica_sets
        for host in layout.hosts
          if host is @config.host
            config.replication.replSetName ?= "#{replSet}"
            checkMapping++
            throw Error 'can attribute one shard server to only one replica set' if checkMapping > 1
      throw Error 'No replica set configured for shard server ', @config.host unless config.replication.replSetName
      # now we are sure that the host belong to one and only one replica set
      # getting back the replica master for our replica set
      for host in mongodb.shard.replica_sets[config.replication.replSetName].hosts
        [ctx] = mongodb_shards.filter( (ctx) -> ctx.config.host is host)
        mongodb.shard.replica_master ?= host if ctx.config.ryba.mongo_shard_replica_master?
      throw Error ' No primary sharding server  configured for replica set' unless mongodb.shard.replica_master?
      mongodb.shard.is_master ?= if mongodb.shard.replica_master is @config.host then true else false
      # now the host knows which server is the replica master and know if its him.

## ShardServer to ConfigServer Mapping
Ryba tries to discover automatically mapping betwwen Shard server Replica Set and
Config server Replica Set.

Each Shard Cluster must be attributed to only one Config server Replica set.
So in the configuration, the administrator must attribute to a config server replica set
the list of Shard Cluster for whose it stores the metadata.

The Mapping can be defined by the replicat_set variable available in `ryba.mongodb.shard.replica_sets`.

      # we  check if shard Cluster is not attributed to different config replica set
      #for now shard server only know to which shard server replica set it is attributed.
      # lest attribute it to a config server replicat set if not one is defnied.
      replSetName = config.replication.replSetName
      configSrvReplSetNames = Object.keys(mongodb.configsrv.replica_sets)
      mongodb.shard.replica_sets[replSetName].configSrvReplSetName ?= configSrvReplSetNames[0]
      if configSrvReplSetNames.indexOf(mongodb.shard.replica_sets[replSetName].configSrvReplSetName) is -1
        throw Error "Unknow Config Server Replicat Set #{mongodb.shard.replica_sets[replSetName].configSrvReplSetName}"

## Process

      config.processManagement ?= {}
      config.processManagement.fork ?= true
      config.processManagement.pidFilePath ?= "#{mongodb.shard.pid_dir}/mongod-shard-server-#{@config.host}.pid"

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
      config.security.sasl.hostName ?= @config.host
      config.security.sasl.serviceName ?= 'mongodb' # Can override only on interprise edition
      mongodb.shard.sasl_password  ?= 'mongodb123'

## Dependencies

    path = require 'path'

[mongod-ssl]:(https://docs.mongodb.org/manual/reference/configuration-options/#net.ssl.mode)
