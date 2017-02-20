
# MongoDB Config Server Install

    module.exports =  header: 'MongoDB Config Server Install', handler: ->
      {mongodb, realm, ssl} = @config.ryba
      {configsrv} = mongodb
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27017 |  tcp  |  configsrv.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @call header: 'IPTables', handler: ->
        @tools.iptables
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: configsrv.config.net.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB Config Server port" }
          ]
          if: @config.iptables.action is 'start'

## Users & Groups

      @call header: 'Users & Groups', handler: ->
        @system.group mongodb.group
        @system.user mongodb.user

## Packages

Install mongodb-org-server containing packages for a mongod service. We render the init scripts
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
                  source: "#{__dirname}/../resources/mongod-config-server.j2"
                  target: '/etc/init.d/mongod-config-server'
                  context: @config
                  mode: 0o0750
                  local: true
                  eof: true
                break;
              when '7'
                @service.init
                  source: "#{__dirname}/../resources/mongod-config-server-redhat-7.j2"
                  target: '/usr/lib/systemd/system/mongod-config-server.service'
                  context: @config
                  mode: 0o0640
                  local: true
                  eof: true
                @system.tmpfs
                  mount: mongodb.configsrv.pid_dir
                  uid: mongodb.user.name
                  gid: mongodb.group.name
                  perm: '0750'
                @service.startup
                  name: 'mongod-config-server'


## Layout

Create dir where the mongodb-config-server stores its metadata

      @call header: 'Layout',  handler: ->
        @mkdir
          target: '/var/lib/mongodb'
          uid: mongodb.user.name
          gid: mongodb.group.name
        @mkdir
          target: mongodb.configsrv.config.storage.dbPath
          uid: mongodb.user.name
          gid: mongodb.group.name
        @mkdir
          if: mongodb.configsrv.config.storage.repairPath?
          target: mongodb.configsrv.config.storage.repairPath
          uid: mongodb.user.name
          gid: mongodb.group.name
        @mkdir
          target: mongodb.configsrv.config.net.unixDomainSocket.pathPrefix
          uid: mongodb.user.name
          gid: mongodb.group.name

## Configure

Configuration file for mongodb config server.

      @call header: 'Configure', handler: ->
        @file.yaml
          target: "#{mongodb.configsrv.conf_dir}/mongod.conf"
          content: mongodb.configsrv.config
          merge: false
          uid: mongodb.user.name
          gid: mongodb.group.name
          mode: 0o0750
          backup: true
        @service.stop
          if: -> @status -1
          name: 'mongod-config-server'

## SSL

Mongod service requires to have in a single file the private key and the certificate
with pem file. So we append to the file the private key and certficate.

      @call header: 'SSL', handler: ->
        @file.download
          source: ssl.cacert
          target: "#{mongodb.configsrv.conf_dir}/cacert.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file.download
          source: ssl.key
          target: "#{mongodb.configsrv.conf_dir}/key_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file.download
          source: ssl.cert
          target: "#{mongodb.configsrv.conf_dir}/cert_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file
          source: "#{mongodb.configsrv.conf_dir}/cert_file.pem"
          target: "#{mongodb.configsrv.conf_dir}/key.pem"
          append: true
          backup: true
          eof: true
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file
          source: "#{mongodb.configsrv.conf_dir}/key_file.pem"
          target: "#{mongodb.configsrv.conf_dir}/key.pem"
          eof: true
          append: true
          uid: mongodb.user.name
          gid: mongodb.group.name

## Kerberos

      @krb5_addprinc krb5,
        header: 'Kerberos Admin'
        principal: "#{mongodb.configsrv.config.security.sasl.serviceName}"#/#{@config.host}@#{realm}"
        password: mongodb.configsrv.sasl_password

# User limits

      @system.limits
        header: 'User Limits'
        user: mongodb.user.name
      , mongodb.user.limits
