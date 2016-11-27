
# MongoDB Routing Server

Deploy the Query Router component of MongoDB. Query router care about Routing
client connection to the different members of the replica set. They are mongos
services

    module.exports =
      use:
        mongodb_configsrvs: 'ryba/mongodb/configsrv'
        mongodb_shards: 'ryba/mongodb/shard'
      configure:
        'ryba/mongodb/router/configure'
      commands:
        'install': [
          'masson/core/yum'
          'masson/core/iptables'
          'masson/core/locale'
          'ryba/mongodb/router/install'
          'ryba/mongodb/router/start'
          'ryba/mongodb/router/sharding'
          'ryba/mongodb/router/check'
        ]
        'start': [
          'ryba/mongodb/router/start'
        ]
        'stop': [
          'ryba/mongodb/router/stop'
        ]
        'status': [
          'ryba/mongodb/router/status'
        ]
        'check': [
          'ryba/mongodb/router/check'
        ]
