
## Configure
Mongodb Config servers have physically no dependances on other mongodb services.
They can be installed and configured on their own.


    module.exports = ->
      mongodb_configsrvs = @contexts 'ryba/mongodb/configsrv'
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
      configsrv_hosts = mongodb_configsrvs.map( (ctx)-> ctx.config.host)
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
      config.systemLog.path ?= "/var/log/mongodb/mongod-config-server-#{@config.host}.log"

## Storage

From 3.2, config servers for sharded clusters can be deployed as a replica set.
The replica set config servers must run the WiredTiger storage engine

      config.storage ?= {}
      config.storage.dbPath ?= "#{mongodb.user.home}/configsrv/db"
      config.storage.repairPath ?= "#{config.storage.dbPath}/repair"
      config.storage.journal ?= {}
      config.storage.journal.enabled ?= true
      if config.storage.repairPath.indexOf(config.storage.dbPath) is -1
        throw Error 'Must use a repairpath that is a subdirectory of dbpath when using journaling' if config.storage.journal.enabled
      config.storage.engine ?= 'wiredTiger'
      throw Error 'Need WiredTiger Storage for config server as replica set' unless config.storage.engine is 'wiredTiger'

## Process

      config.processManagement ?= {}
      config.processManagement.fork ?= true
      config.processManagement.pidFilePath ?= "#{mongodb.configsrv.pid_dir}/mongod-config-server-#{@config.host}.pid"

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
Kerberos authentication is only avaiable in enterprise edition.

      config.security.sasl ?= {}
      config.security.sasl.hostName ?= @config.host
      config.security.sasl.serviceName ?= 'mongodb' # Can override only on enterprise edition
      mongodb.configsrv.sasl_password  ?= 'mongodb123'

## Replicat Set Discovery
Deploys config server as replica set. You can configure a custom layout by giving
an object containing a list of replica set name and the associated hosts.
By default Ryba deploys only one replica set for all the config server.

By default config servers replica set layout is not defined `mongodb.configsrv.replica_sets`.
Ryba uses all the config server available to create a replica set of config server.

      config.replication ?= {}
      mongodb.configsrv.replica_sets ?=
        configsrvRepSet1:
          hosts: configsrv_hosts
      # we  check if every config server is maped to one and only one config  replica set name.
      replSets = Object.keys(mongodb.configsrv.replica_sets)
      throw Error 'No replica sets found for config servers' unless replSets.length > 0
      checkMapping = 0
      for replSet, layout of mongodb.configsrv.replica_sets
        throw Error "no hosts defined for config replica set #{replSet}" unless layout.hosts.length? > 0
        for host in layout.hosts
          if host is @config.host
            config.replication.replSetName ?= "#{replSet}"
            checkMapping++
            throw Error 'can attribute one config server to only one replica set' if checkMapping > 1
      throw Error 'No replica set configured for config server ', @config.host unless config.replication.replSetName
      # now we are sure that the host belong to one and only one replica set
      # getting back the replica master for our replica set
      for host in mongodb.configsrv.replica_sets[config.replication.replSetName].hosts
        [ctx] = mongodb_configsrvs.filter( (ctx) -> ctx.config.host is host)
        mongodb.configsrv.replica_master ?= host if ctx.config.ryba.mongo_config_replica_master?
      throw Error ' No master configured for replica set' unless mongodb.configsrv.replica_master?
      mongodb.configsrv.is_master ?= mongodb.configsrv.replica_master is @config.host
      # now the host knows which server is the replica primary server and know if its him.

## Dependencies

    path = require 'path'

[mongod-ssl]:(https://docs.mongodb.org/manual/reference/configuration-options/#net.ssl.mode)
