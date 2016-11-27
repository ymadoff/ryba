
# MongoDB Config Server (Distributed)

MongoDB is a document-oriented database. Distributed Version.

Config servers are special mongod instances that store the metadata for a
sharded cluster.
All config servers must be available to deploy a sharded cluster or to make any
changes to cluster metadata.

    module.exports =
      use: 
        core_local: implicit: true, module: 'masson/core/locale'
        iptables: implicit: true, module: 'masson/core/iptables'
      configure:
        'ryba/mongodb/configsrv/configure'
      commands:
        'install': [
          'ryba/mongodb/configsrv/install'
          'ryba/mongodb/configsrv/start'
          'ryba/mongodb/configsrv/replication'
          'ryba/mongodb/configsrv/check'
        ]
        'check':
          'ryba/mongodb/configsrv/check'
        'start':
          'ryba/mongodb/configsrv/start'
        'stop':
          'ryba/mongodb/configsrv/stop'
        'status':
          'ryba/mongodb/configsrv/status'
