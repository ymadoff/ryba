
# MongoDB Router Server Replica Set Initialization

    module.exports =  header: 'MongoDB Router Servers Replicat Set', handler: ->
      {mongodb, realm, ssl} = @config.ryba
      {shard} = mongodb
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      mongo_shell_exec =  "mongo admin --port #{shard.config.net.port}"
      mongo_shell_admin_exec =  "#{mongo_shell_exec} -u #{mongodb.admin.name} --password  '#{mongodb.admin.password}'"
      mongo_shell_root_exec =  "#{mongo_shell_exec} -u #{mongodb.root.name} --password  '#{mongodb.root.password}'"
      # the userAdminAnyDatabase role is the first account created thanks to locahost exception
      # it used to manage every other user and their roles, for the root user
      # having the right to deal with privileges does not give it the role of root (ie  manage replica sets)
      mongodb_admin =
        user: "#{mongodb.admin.name}"
        pwd: "#{mongodb.admin.password}"
        roles:  [ { role: "userAdminAnyDatabase", db: "admin" }]
      mongodb_root =
        user: "#{mongodb.root.name}"
        pwd: "#{mongodb.root.password}"
        roles: [ { role: "root", db: "admin" } ]

## Wait

      @call once: true, 'ryba/mongodb/shard/wait'

# Admin Users

Create the admin user and root user as specified. It uses the LocalHost Exception to
bind to mongod instance in order to create user without authentication.
The admin user is need for account creation and has the role `userAdminAnyDatabase`.
The root user is needed for replication and has role `root`

      @call
        header: 'MongoDB Shard Server # Roles Admin DB',
        if: @config.host is mongodb.shard.replica_master
        unless_exec: """
          echo exit | #{mongo_shell_admin_exec}
          echo exit | #{mongo_shell_root_exec}
        """
        handler: ->
          @service.stop
            name: 'mongodb-shard-server'
          @file.yaml
            target: "#{mongodb.shard.conf_dir}/mongod.conf"
            content:
              replication: null
            merge: true
            uid: mongodb.user.name
            gid: mongodb.group.name
            mode: 0o0750
            backup: true
          @service.start
            name: 'mongodb-shard-server'
          @connection.wait
            host: @config.host
            port: mongodb.shard.config.net.port
          @execute
            cmd: """
              #{mongo_shell_exec} --eval <<-EOF \
              'printjson( db.createUser( \
                { user: \"#{mongodb.admin.name}\", pwd: \"#{mongodb.admin.password}\", roles: [ { role: \"userAdminAnyDatabase\", db: \"admin\" }]} \
              ))'
              EOF
            """
            unless_exec: """
              echo exit | #{mongo_shell_admin_exec} -u #{mongodb.admin.name} --password  '#{mongodb.admin.password}'
              """
            code_skipped: 252
          @execute
            cmd: """
            #{mongo_shell_admin_exec} --eval <<-EOF \
            'printjson(db.createUser( \
              { user: \"#{mongodb.root.name}\", pwd: \"#{mongodb.root.password}\", roles: [ { role: \"root\", db: \"admin\" }]} \
            ))'
            EOF
            """
            unless_exec: "echo exit | #{mongo_shell_admin_exec} -u #{mongodb.root.name} --password  '#{mongodb.root.password}'"
            code_skipped: 252
          @file.yaml
            target: "#{mongodb.shard.conf_dir}/mongod.conf"
            content: mongodb.shard.config
            merge: true
            uid: mongodb.user.name
            gid: mongodb.group.name
            mode: 0o0750
            backup: true
          @service.stop
            if: -> @status -1
            name: 'mongodb-shard-server'
          @service.start
            if: -> @status -1
            name: 'mongodb-shard-server'
          @connection.wait
            host: @config.host
            port: mongodb.shard.config.net.port


# Replica Set Initialization

Initializes the replica set by connecting to the designated primary shard server
and launching the 'rs.initiate()' command.

      @call
        header: 'MongoDB Shard Server # Replica Set Init Master'
        if: @config.host is mongodb.shard.replica_master
        timeout: -1
        handler: ->
          message = {}
          @call (_, callback) ->
            @execute
              cmd: " #{mongo_shell_root_exec}  --eval 'rs.status().ok' | grep -v 'MongoDB shell version' | grep -v 'connecting to:'"
            , (err, _, stdout) ->
              return callback err if err
              status =  parseInt(stdout)
              return callback null, true if status == 0
              callback null, false
          @execute
            if: -> @status -1
            cmd: "#{mongo_shell_root_exec}  --eval 'rs.initiate()'"

# Replica Set Members

Adds the other shard servers members of the replica set.

      @call
        header: 'MongoDB Shard Server # Replica Set Init Master'
        if: @config.host is mongodb.shard.replica_master
        timeout: -1
        handler: ->
          message = {}
          @call ->
            replSetName = mongodb.shard.config.replication.replSetName
            for host in mongodb.shard.replica_sets[replSetName]
              @execute
                cmd: "#{mongo_shell_root_exec} --eval 'rs.add(\"#{host}:#{mongodb.shard.config.net.port}\")'"
                unless_exec: "#{mongo_shell_root_exec} --eval 'rs.conf().members' | grep '#{host}:#{mongodb.shard.config.net.port}'"
