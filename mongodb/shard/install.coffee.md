
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

      @call header: 'IPTables', handler: ->
        @tools.iptables
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: shard.config.net.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB Shard Server port" }
          ]
          if: @config.iptables.action is 'start'

## Users & Groups

      @call header: 'Users & Groups', handler: ->
        @system.group mongodb.group
        @system.user mongodb.user

## Packages

Install mongod-org-server containing packages for a mongod service. We render the init scripts
in order to rendered configuration file with custom properties.

      @call header: 'Packages', timeout: -1, handler: (options) ->
        @service name: 'mongodb-org-server'
        @service name: 'mongodb-org-shell'
        @service name: 'mongodb-org-tools'
        @call
          header: 'RPM'
          if: -> (options.store['mecano:system:type'] in ['redhat','centos'])
          handler: ->
            switch options.store['mecano:system:release'][0]
              when '6'
                @service.init
                  source: "#{__dirname}/../resources/mongod-shard-server.j2"
                  target: '/etc/init.d/mongod-shard-server'
                  context: @config
                  mode: 0o0750
                  local: true
                  eof: true
                break;
              when '7'
                @service.init
                  source: "#{__dirname}/../resources/mongod-shard-server-redhat-7.j2"
                  target: '/usr/lib/systemd/system/mongod-shard-server.service'
                  context: @config
                  mode: 0o0640
                  local: true
                  eof: true
                @system.tmpfs
                  mount: mongodb.shard.pid_dir
                  uid: mongodb.user.name
                  gid: mongodb.group.name
                  perm: '0750'

## Layout

Create dir where the mongod-shard-server stores its metadata

      @call header: 'Layout',  handler: ->
        @system.mkdir
          target: '/var/lib/mongodb'
          uid: mongodb.user.name
          gid: mongodb.group.name
        @system.mkdir
          target: mongodb.shard.config.storage.dbPath
          uid: mongodb.user.name
          gid: mongodb.group.name
        @system.mkdir
          if: mongodb.shard.config.storage.repairPath?
          target: mongodb.shard.config.storage.repairPath
          uid: mongodb.user.name
          gid: mongodb.group.name
        @system.mkdir
          target: mongodb.shard.config.net.unixDomainSocket.pathPrefix
          uid: mongodb.user.name
          gid: mongodb.group.name

## Configure

Configuration file for mongodb sharding server.

      @call header: 'Configure', handler: ->
        @file.yaml
          target: "#{mongodb.shard.conf_dir}/mongod.conf"
          content: mongodb.shard.config
          merge: false
          uid: mongodb.user.name
          gid: mongodb.group.name
          mode: 0o0750
          backup: true
        @service.stop
          if: -> @status -1
          name: 'mongod-shard-server'

## SSL

Mongod service requires to have in a single file the private key and the certificate
with pem file. So we append to the file the private key and certficate.

      @call header: 'SSL', handler: ->
        @file.download
          source: ssl.cacert
          target: "#{mongodb.shard.conf_dir}/cacert.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file.download
          source: ssl.key
          target: "#{mongodb.shard.conf_dir}/key_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file.download
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

      @call header: 'Kerberos Admin', handler: ->
        @krb5_addprinc krb5,
          principal: "#{mongodb.shard.config.security.sasl.serviceName}"#/#{@config.host}@#{realm}"
          password: mongodb.shard.sasl_password

# User limits

      @system.limits
        header: 'User Limits'
        user: mongodb.user.name
      , mongodb.user.limits
