
# MongoDB Config Server Install

    module.exports =  header: 'MongoDB Config Server Install', handler: ->
      {mongodb, realm, ssl} = @config.ryba
      {configsrv} = mongodb
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27017 |  tcp  |  configsrv.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @call header: 'MongoDB Config Server # IPTables', handler: ->
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

      @call header: 'MongoDB Config Server # Packages', timeout: -1, handler: ->
        @service name: 'mongodb-org-server'
        @service name: 'mongodb-org-shell'
        @render
          source: "#{__dirname}/../resources/mongod-config-server.js2"
          destination: '/etc/init.d/mongodb-config-server'
          context: @config
          unlink: true
          mode: 0o0750
          local_source: true
          eof: true
        @remove
          destination: '/etc/init.d/mongod'
          

## Layout

Create dir where the mongodb-config-server stores its metadata

      @call header: 'MongoDB Config Server # Layout',  handler: ->
        @mkdir
          destination: '/var/lib/mongodb'
          uid: mongodb.user.name
          gid: mongodb.group.name
        @mkdir
          destination: mongodb.configsrv.config.storage.dbPath
          uid: mongodb.user.name
          gid: mongodb.group.name
        @mkdir
          destination: mongodb.configsrv.config.storage.repairPath
          uid: mongodb.user.name
          gid: mongodb.group.name
        @mkdir
          destination: mongodb.configsrv.config.net.unixDomainSocket.pathPrefix
          uid: mongodb.user.name
          gid: mongodb.group.name

## Configure

Configuration file for mongodb config server.

      @call header: 'MongoDB Config Server # Configure', handler: ->
        @yaml
          destination: "#{mongodb.configsrv.conf_dir}/mongod.conf"
          content: mongodb.configsrv.config
          merge: false
          uid: mongodb.user.name
          gid: mongodb.group.name
          mode: 0o0750
          backup: true
        @service_stop
          if: -> @status -1
          name: 'mongodb-config-server'

## SSL

Mongod service requires to have in a single file the private key and the certificate
with pem file. So we append to the file the private key and certficate.

      @call header: 'MongoDB Config Server # SSL', handler: ->
        @upload
          source: ssl.cacert
          destination: "#{mongodb.configsrv.conf_dir}/cacert.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @upload
          source: ssl.key
          destination: "#{mongodb.configsrv.conf_dir}/key_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @upload
          source: ssl.cert
          destination: "#{mongodb.configsrv.conf_dir}/cert_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @write
          source: "#{mongodb.configsrv.conf_dir}/cert_file.pem"
          destination: "#{mongodb.configsrv.conf_dir}/key.pem"
          append: true
          backup: true
          eof: true
          uid: mongodb.user.name
          gid: mongodb.group.name
        @write
          source: "#{mongodb.configsrv.conf_dir}/key_file.pem"
          destination: "#{mongodb.configsrv.conf_dir}/key.pem"
          eof: true
          append: true
          uid: mongodb.user.name
          gid: mongodb.group.name

## Kerberos

      @call header: 'MongoDB Config Server # Kerberos Admin', handler: ->
        @krb5_addprinc
          principal: "#{mongodb.configsrv.config.security.sasl.serviceName}"#/#{@config.host}@#{realm}"
          password: mongodb.configsrv.sasl_password
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server

# User limits

      @call header: 'MongoDB Config Server # User Limits', handler: ->
        @system_limits
          user: mongodb.user.name
          nofile: mongodb.user.limits.nofile
          nproc: mongodb.user.limits.nproc
