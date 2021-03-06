
# MongoDB Add Shards to the Cluster


 Connect to the mongos instance and Add each Shard to the cluster using the sh.addShard().
 In our case each Shard is a replicat set of sharding server (mongod instances).
 We add only the primary designated sharing mongod instance (called the seed) to the Cluster.
 It will automatically add the other (mongod intance) replica set members to the cluster.
 Once done, the Sharded Cluster will be available for the mongodb.
 available does not mean used, the db admin has to manually add a shard to a database

    module.exports =  header: 'MongoDB Router Servers Shard Cluster', handler: ->
      [mongodb_configsrv] = @contexts 'ryba/mongodb/configsrv'
      mongodb_shards = @contexts 'ryba/mongodb/shard'
      {mongodb} = @config.ryba
      {router} = mongodb
      {replica_sets} = mongodb_configsrv.config.ryba.mongodb.configsrv
      shards = mongodb.router.my_shards_repl_sets
      mongo_shell_exec =  "mongo admin "
      shard_port = mongodb_shards[0].config.ryba.mongodb.shard.config.net.port
      shard_root = mongodb_shards[0].config.ryba.mongodb.root
      mongos_port =  router.config.net.port

# Wait Shard to be available

We simply wait to connect to the shards

      @call header: 'Wait Sharding Server', ->
        @call ->
          for ctx in mongodb_shards
            @connection.wait
              if:  ctx.config.ryba.mongodb.shard.config.replication.replSetName in shards
              host: ctx.config.host
              port: ctx.config.ryba.mongodb.shard.config.net.port

# Add shard to the cluster

To add s shard to the cluster, the command `sh.addShard("shardsrvRepSet1/primary.ryba:27017")`
must be issued to mongos.
So the primary server must be retrieved before applying this command. Because the replica set has a not a dedicated primary server,
We must connect to each server og the replica set manually and check if it is the primary one.


      @call header: 'Add Shard Clusters ', retry: 3, ->
        @each shards, (options, next) ->
          shard = options.key
          primary_host = null
          shard_hosts = mongodb_shards.map (ctx) ->
            if ctx.config.ryba.mongodb.shard.config.replication.replSetName is shard
              ctx.config.host
          shard_quorum = shard_hosts.map( (host) -> "#{host}:#{shard_port}").join(',')
          @call
            unless_exec: """
             #{mongo_shell_exec} --host #{@config.host} --port #{mongos_port} \
               -u #{shard_root.name} --password '#{shard_root.password}' \
               --eval 'sh.status()' | grep '.*#{shard}.*#{shard}/#{shard_quorum}'
            """
          , ->
            @each shard_hosts, (options) ->
              host = options.key
              @system.execute
                code_skipped: 1
                cmd: """
                #{mongo_shell_exec} --host #{host} \
                  --port #{shard_port} -u #{shard_root.name} --password '#{shard_root.password}' \
                  --eval 'db.isMaster().primary' | grep '#{host}:#{shard_port}' \
                  | grep -v 'MongoDB.*version' | grep -v 'connecting to:'
                """
              @call if: (-> @status -1), -> primary_host = host
            @call ->
              @system.execute
                if: -> primary_host
                cmd: """
                #{mongo_shell_exec} --host #{@config.host} --port #{mongos_port} \
                  -u #{shard_root.name} --password '#{shard_root.password}' \
                  --eval 'sh.addShard(\"#{shard}/#{primary_host}:#{shard_port}\")'
                """
          @then next
