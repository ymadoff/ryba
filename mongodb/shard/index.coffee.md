
# MongoDB Shard (Distributed)

MongoDB is a document-oriented database. Distributed Version

Config servers are special mongod instances that store the metadata for a
sharded cluster.
All config servers must be available to deploy a sharded cluster or to make any
changes to cluster metadata.

    module.exports =
      use:
        mongodb_routers: 'ryba/mongodb/router'
        mongodb_clients: 'ryba/mongodb/client'
        mongodb_shards: 'ryba/mongodb/shard'
      configure:
        'ryba/mongodb/shard/configure'
      commands:
        'install': [
          'masson/core/locale'
          'ryba/mongodb/shard/install'
          'ryba/mongodb/shard/start'
          'ryba/mongodb/shard/replication'
          'ryba/mongodb/shard/check'
        ]
        'start':
          'ryba/mongodb/shard/start'
        'stop':
          'ryba/mongodb/shard/stop'
        'status':
          'ryba/mongodb/shard/status'
