
# MongoDB Config Server (Distributed)

MongoDB is a document-oriented database. Distributed Version.

Config servers are special mongod instances that store the metadata for a
sharded cluster.
All config servers must be available to deploy a sharded cluster or to make any
changes to cluster metadata.

    module.exports = ->
      'configure': [
        'ryba/mongodb/configsrv/configure'
      ]
      'install': [
        'masson/core/locale'
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
