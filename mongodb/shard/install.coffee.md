
# MongoDB Config Server Install

    module.exports =  header: 'MongoDB Shard Server Install', handler: ->
      {mongodb, realm, ssl} = @config.ryba
      {shard} = mongodb
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27019 |  tcp  |  shard.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @call once: true, 'masson/core/iptables'
      @call header: 'MongoDB Shard Server # IPTables', handler: ->
        @iptables
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: shard.config.net.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB Shard Server port" }
          ]
          if: @config.iptables.action is 'start'

## Users & Groups

      @call header: 'MongoDB # Users & Groups', handler: ->
        @group mongodb.group
        @user mongodb.user

## Packages

Install mongodb-org-server containing packages for a mongod service. We render the init scripts
in order to rendered configuration file with custom properties.

      @call header: 'MongoDB Config Server # Packages', timeout: -1, handler: ->
        @service name: 'mongodb-org-server'
        @service name: 'mongodb-org-shell'
        @render
          source: "#{__dirname}/../resources/mongod-shard-server.js2"
          target: '/etc/init.d/mongodb-shard-server'
          context: @config
          backup: true
          mode: 0o0750
          local_source: true
          eof: true
        @remove
          target: '/etc/init.d/mongod'

## Layout

Create dir where the mongodb-shard-server stores its metadata

      @call header: 'MongoDB Shard Server # Layout',  handler: ->
        @mkdir
          target: '/var/lib/mongodb'
          uid: mongodb.user.name
          gid: mongodb.group.name
        @mkdir
          target: mongodb.shard.config.storage.dbPath
          uid: mongodb.user.name
          gid: mongodb.group.name
        @mkdir
          target: mongodb.shard.config.storage.repairPath
          uid: mongodb.user.name
          gid: mongodb.group.name
        @mkdir
          target: mongodb.shard.config.net.unixDomainSocket.pathPrefix
          uid: mongodb.user.name
          gid: mongodb.group.name

## Configure

Configuration file for mongodb sharding server.

      @call header: 'MongoDB Shard Server # Configure', handler: ->
        @file.yaml
          target: "#{mongodb.shard.conf_dir}/mongod.conf"
          content: mongodb.shard.config
          merge: false
          uid: mongodb.user.name
          gid: mongodb.group.name
          mode: 0o0750
          backup: true
        @service_stop
          if: -> @status -1
          name: 'mongodb-shard-server'

## SSL

Mongod service requires to have in a single file the private key and the certificate
with pem file. So we append to the file the private key and certficate.

      @call header: 'MongoDB Shard Server # SSL', handler: ->
        @download
          source: ssl.cacert
          target: "#{mongodb.shard.conf_dir}/cacert.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @download
          source: ssl.key
          target: "#{mongodb.shard.conf_dir}/key_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @download
          source: ssl.cert
          target: "#{mongodb.shard.conf_dir}/cert_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file
          source: "#{mongodb.shard.conf_dir}/cert_file.pem"
          target: "#{mongodb.shard.conf_dir}/key.pem"
          append: true
          backup: true
          eof: true
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file
          source: "#{mongodb.shard.conf_dir}/key_file.pem"
          target: "#{mongodb.shard.conf_dir}/key.pem"
          eof: true
          append: true
          uid: mongodb.user.name
          gid: mongodb.group.name

## Kerberos

      @call header: 'MongoDB Shard Server # Kerberos Admin', handler: ->
        @krb5_addprinc krb5,
          principal: "#{mongodb.shard.config.security.sasl.serviceName}"#/#{@config.host}@#{realm}"
          password: mongodb.shard.sasl_password

# User limits

      @call header: 'MongoDB Shard Server # User Limits', handler: ->
        @system_limits
          user: mongodb.user.name
          nofile: mongodb.user.limits.nofile
          nproc: mongodb.user.limits.nproc
