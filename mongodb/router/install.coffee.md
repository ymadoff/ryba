
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

      @tools.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: router.config.net.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB Router Server port" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

      @system.group header: 'Group', mongodb.group
      @system.user header: 'User', mongodb.user

## Packages

Install mongod-org-server containing packages for a mongod service. We render the init scripts
in order to rendered configuration file with custom properties.

      @call header: 'Packages', timeout: -1, (options) ->
        @service name: 'mongodb-org-mongos'
        @service name: 'mongodb-org-shell'
        @service name: 'mongodb-org-tools'
        @system.discover (err, status, os) ->
          @call
            header: 'RPM'
            if: -> (os.type in ['redhat','centos'])
          , ->
            switch os.release[0]
              when '6'
                @file.render
                  source: "#{__dirname}/../resources/mongod-router-server.j2"
                  target: '/etc/init.d/mongod-router-server'
                  context: @config
                  unlink: true
                  mode: 0o0750
                  local: true
                  eof: true
                break;
              when '7'
                @service.init
                  source: "#{__dirname}/../resources/mongod-router-server-redhat-7.j2"
                  target: '/usr/lib/systemd/system/mongod-router-server.service'
                  context: @config
                  mode: 0o0640
                  local: true
                  eof: true
                @system.tmpfs
                  mount: mongodb.router.pid_dir
                  uid: mongodb.user.name
                  gid: mongodb.group.name
                  perm: '0750'
                @service.startup
                  name: 'mongod-config-server'

## Layout

Create dir where the mongod-config-server stores its metadata

      @system.mkdir
        header: 'Layout'
        target: '/var/lib/mongodb'
        uid: mongodb.user.name
        gid: mongodb.group.name


## Configure

Configuration file for mongodb config server.

      @call header: 'Configure', ->
        @file.yaml
          target: "#{mongodb.router.conf_dir}/mongos.conf"
          content: mongodb.router.config
          merge: false
          uid: mongodb.user.name
          gid: mongodb.group.name
          mode: 0o0750
          backup: true
        @service.stop
          if: -> @status -1
          name: 'mongod-router-server'

## SSL

Mongod service requires to have in a single file the private key and the certificate
with pem file. So we append to the file the private key and certficate.

      @call header: 'SSL', ->
        @file.download
          source: ssl.cacert
          target: "#{mongodb.router.conf_dir}/cacert.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file.download
          source: ssl.key
          target: "#{mongodb.router.conf_dir}/key_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file.download
          source: ssl.cert
          target: "#{mongodb.router.conf_dir}/cert_file.pem"
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file
          source: "#{mongodb.router.conf_dir}/cert_file.pem"
          target: "#{mongodb.router.conf_dir}/key.pem"
          append: true
          backup: true
          eof: true
          uid: mongodb.user.name
          gid: mongodb.group.name
        @file
          source: "#{mongodb.router.conf_dir}/key_file.pem"
          target: "#{mongodb.router.conf_dir}/key.pem"
          eof: true
          append: true
          uid: mongodb.user.name
          gid: mongodb.group.name

# User limits

      @system.limits
        header: 'User Limits'
        user: mongodb.user.name
      , mongodb.user.limits
