
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

      @call once: true, 'masson/core/iptables'
      @call header: 'IPTables', handler: ->
        @iptables
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: configsrv.config.net.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB Config Server port" }
          ]
          if: @config.iptables.action is 'start'

## Users & Groups

      @call header: 'MongoDB # Users & Groups', handler: ->
        @group mongodb.group
        @user mongodb.user

## Packages

Install mongodb-org-server containing packages for a mongod service. We render the init scripts
in order to rendered configuration file with custom properties.

      @call header: 'Packages', timeout: -1, handler: ->
        @service name: 'mongodb-org-server'
        @service name: 'mongodb-org-shell'
        @render
          source: "#{__dirname}/../resources/mongod-config-server.js2"
          target: '/etc/init.d/mongodb-config-server'
          context: @config
          unlink: true
          mode: 0o0750
          local_source: true
          eof: true
        @remove
          target: '/etc/init.d/mongod'


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
          name: 'mongodb-config-server'

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

      @call header: 'Kerberos Admin', handler: ->
        @krb5_addprinc krb5,
          principal: "#{mongodb.configsrv.config.security.sasl.serviceName}"#/#{@config.host}@#{realm}"
          password: mongodb.configsrv.sasl_password

# User limits

      @system_limits
        header: 'User Limits'
        user: mongodb.user.name
        nofile: mongodb.user.limits.nofile
        nproc: mongodb.user.limits.nproc
