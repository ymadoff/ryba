
# MongoDB Config Server Install

    module.exports =  header: 'MongoDB Router Install', handler: ->
      {mongodb, realm, ssl} = @config.ryba
      {router} = mongodb
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27018 |  tcp  |  configsrv.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: router.config.net.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB Router Server port" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

      @group header: 'Users', mongodb.group
      @user header: 'Groups', mongodb.user

## Packages

Install mongodb-org-server containing packages for a mongod service. We render the init scripts
in order to rendered configuration file with custom properties.

      @call header: 'Packages', timeout: -1, handler: ->
        @service name: 'mongodb-org-mongos'
        @service name: 'mongodb-org-shell'
        @render
          source: "#{__dirname}/../resources/mongod-router-server.js2"
          destination: '/etc/init.d/mongodb-router-server'
          context: @config
          unlink: true
          mode: 0o0750
          local_source: true
          eof: true
        @remove
          destination: '/etc/init.d/mongod'

## Layout

Create dir where the mongodb-config-server stores its metadata

      @mkdir
        header: 'Layout'
        destination: '/var/lib/mongodb'
        uid: mongodb.user.name
        gid: mongodb.group.name


## Configure

Configuration file for mongodb config server.

      @call header: 'Configure', handler: ->
        @write_yaml
          destination: "#{mongodb.router.conf_dir}/mongos.conf"
          content: mongodb.router.config
          merge: false
          uid: mongodb.user.name
          gid: mongodb.group.name
          mode: 0o0750
          backup: true
        @service_stop
          if: -> @status -1
          name: 'mongodb-router-server'

## SSL

Mongod service requires to have in a single file the private key and the certificate
with pem file. So we append to the file the private key and certficate.

      @call header: 'SSL', handler: ->
        @download
          source: ssl.cacert
          destination: "#{mongodb.router.conf_dir}/cacert.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @download
          source: ssl.key
          destination: "#{mongodb.router.conf_dir}/key_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @download
          source: ssl.cert
          destination: "#{mongodb.router.conf_dir}/cert_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @write
          source: "#{mongodb.router.conf_dir}/cert_file.pem"
          destination: "#{mongodb.router.conf_dir}/key.pem"
          append: true
          backup: true
          eof: true
          uid: mongodb.user.name
          gid: mongodb.group.name
        @write
          source: "#{mongodb.router.conf_dir}/key_file.pem"
          destination: "#{mongodb.router.conf_dir}/key.pem"
          eof: true
          append: true
          uid: mongodb.user.name
          gid: mongodb.group.name

# User limits

      @system_limits
        header: 'User Limits'
        user: mongodb.user.name
        nofile: mongodb.user.limits.nofile
        nproc: mongodb.user.limits.nproc
