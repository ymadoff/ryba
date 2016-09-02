
# MongoDB Config Server Replica Set Initialization

    module.exports =  header: 'MongoDB ConfigSrv Replicat Set', handler: ->
      {mongodb, realm, ssl} = @config.ryba
      {configsrv} = mongodb
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      mongo_shell_exec =  "mongo admin --port #{configsrv.config.net.port}"
      mongo_shell_admin_exec =  "#{mongo_shell_exec} -u #{mongodb.admin.name} --password  #{mongodb.admin.password}"
      mongo_shell_root_exec =  "#{mongo_shell_exec} -u #{mongodb.root.name} --password  #{mongodb.root.password}"
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

      @call once: true, 'ryba/mongodb/configsrv/wait'

# Admin Users

Create the admin user and root user as specified. It uses the LocalHost Exception to
bind to mongod instance in order to create user without authentication.
The admin user is need for account creation and has the role `userAdminAnyDatabase`.
The root user is needed for replication and has role `root`

      @call
        header: 'MongoDB ConfigSrv # Roles Admin DB',
        if: @config.host is mongodb.configsrv.replica_master
        unless_exec: """
          echo exit | #{mongo_shell_admin_exec}
          echo exit | #{mongo_shell_root_exec}
        """
        handler: ->
          @service_stop
            name: 'mongodb-config-server'
          @file.yaml
            target: "#{mongodb.configsrv.conf_dir}/mongod.conf"
            content:
              replication: null
            merge: true
            uid: mongodb.user.name
            gid: mongodb.group.name
            mode: 0o0750
            backup: true
          @service_start
            name: 'mongodb-config-server'
          @wait_connect
            host: @config.host
            port: mongodb.configsrv.config.net.port
          @execute
            cmd: """
              #{mongo_shell_exec} --eval <<-EOF \
              'printjson( db.createUser( \
                { user: \"#{mongodb.admin.name}\", pwd: \"#{mongodb.admin.password}\", roles: [ { role: \"userAdminAnyDatabase\", db: \"admin\" }]} \
              ))'
              EOF
            """
            unless_exec: """
              echo exit | #{mongo_shell_admin_exec} -u #{mongodb.admin.name} --password  #{mongodb.admin.password}
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
            unless_exec: "echo exit | #{mongo_shell_admin_exec} -u #{mongodb.root.name} --password  #{mongodb.root.password}"
            code_skipped: 252
          @file.yaml
            target: "#{mongodb.configsrv.conf_dir}/mongod.conf"
            content: mongodb.configsrv.config
            merge: true
            uid: mongodb.user.name
            gid: mongodb.group.name
            mode: 0o0750
            backup: true
          @service_stop
            if: -> @status -1
            name: 'mongodb-config-server'
          @service_start
            if: -> @status -1
            name: 'mongodb-config-server'
          @wait_connect
            host: @config.host
            port: mongodb.configsrv.config.net.port


# Replica Set Initialization

      @call
        header: 'MongoDB ConfigSrv # Replica Set Init Master'
        if: @config.host is mongodb.configsrv.replica_master
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

      @call
        header: 'MongoDB ConfigSrv # Replica Set Init Master'
        if: @config.host is mongodb.configsrv.replica_master
        timeout: -1
        handler: ->
          message = {}
          @call ->
            replSetName = mongodb.configsrv.config.replication.replSetName
            for host in mongodb.configsrv.replica_sets[replSetName]
              @execute
                cmd: "#{mongo_shell_root_exec} --eval 'rs.add(\"#{host}:#{mongodb.configsrv.config.net.port}\")'"
                unless_exec: "#{mongo_shell_root_exec} --eval 'rs.conf().members' | grep '#{host}:#{mongodb.configsrv.config.net.port}'"
