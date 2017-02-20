
# Knox Install

    module.exports = header: 'Knox Install', handler: ->
      {knox, realm} = @config.ryba
      {java_home, jre_home} = @config.java
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Users & Groups

      @system.group knox.group
      @system.user knox.user

## IPTables

| Service        | Port  | Proto | Parameter       |
|----------------|-------|-------|-----------------|
| Gateway        | 8443  | http  | gateway.port    |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: knox.site['gateway.port'], protocol: 'tcp', state: 'NEW', comment: "Knox Gateway" }
        ]
        if: @config.iptables.action is 'start'

## Packages

      @call header: 'Packages', timeout: -1, handler: (options) ->
        @service name: 'knox'
        @hdp_select name: 'knox-server'
        # Fix autogen of master secret
        @call 
          if: ->@status -2
        , ->
          @each  [
            '/usr/hdp/current/knox-server/data/security/master'
            '/usr/hdp/current/knox-server/data/security/keystores'
            '/usr/hdp/current/knox-server/conf/topologies/admin.xml'
            '/usr/hdp/current/knox-server/conf/topologies/sandbox.xml'
          ] , (options) ->
              @remove  target: options.key
        @system.chown
          target: '/var/log/knox'
          uid: knox.user.name
          gid: knox.user.gid
        @service.init
          target: '/etc/init.d/knox-server'
          source: "#{__dirname}/resources/knox-server.j2"
          local: true
          context: @config.ryba.knox
          mode: 0o755
        @system.tmpfs
          if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
          mount: "/var/run/#{knox.user.name}"
          uid: knox.user.name
          gid: knox.group.name
          perm: '0750'

## Configure

      @hconfigure
        header: 'Configure'
        target: "#{knox.conf_dir}/gateway-site.xml"
        properties: knox.site
        merge: true

      @render
        header: 'Knox Ldap Caching'
        target: "#{knox.conf_dir}/ehcache.xml"
        source: "#{__dirname}/resources/ehcache.j2"
        local_source: true

## Env

We do not edit knox-env.sh because environnement variables are directly set
in the gateway.sh service script.

      @call header: 'Env', handler: ->
        knox.env.app_log_opts += "-D#{k}=#{v}" for k,v of knox.log4jopts
        @file
          header: 'Env'
          target: "#{knox.conf_dir}/gateway.sh"
          write: for k, v of knox.env
            match: new RegExp "^#{k}=.*$", 'i'
            replace: "#{k.toUpperCase()}=\"#{v}\""
            append: true

## Kerberos

      @call header: 'Kerberos', handler: ->
        @krb5_addprinc krb5,
          principal: knox.krb5_user.principal
          randkey: true
          keytab: knox.krb5_user.keytab
          uid: knox.user.name
          gid: knox.group.name
        @file.jaas
          target: knox.site['java.security.auth.login.config']
          content: 'com.sun.security.jgss.initiate':
            principal: knox.krb5_user.principal
            keyTab: knox.krb5_user.keytab
            renewTGT: true
            doNotPrompt: true
            isInitiator: true
            useTicketCache: true
            client: true
          no_entry_check: true
          uid: knox.user.name
          gid: knox.group.name
          mode: 0o600

## Topologies

      @call header: 'Topologies', handler: ->
        for nameservice, topology of knox.topologies
          doc = builder.create 'topology', version: '1.0', encoding: 'UTF-8'
          gateway = doc.ele 'gateway' if topology.providers?
          for role, p of topology.providers
            provider = gateway.ele 'provider'
            provider.ele 'role', role
            provider.ele 'name', p.name
            provider.ele 'enabled', if p.enabled? then "#{p.enabled}" else 'true'
            if typeof p.config is 'object'
              for name in Object.keys(p.config).sort()
                if p.config[name]
                  param = provider.ele 'param'
                  param.ele 'name', name
                  param.ele 'value', p.config[name]
          for role, url of topology.services
            unless url is false
              service = doc.ele 'service'
              service.ele 'role', role.toUpperCase()
              if Array.isArray url then for u in url
                service.ele 'url', u
              else if url not in [null, ''] then service.ele 'url', url
          @file
            target: "#{knox.conf_dir}/topologies/#{nameservice}.xml"
            content: doc.end pretty: true
            backup: true
            eof: true

          @render
            target: "#{knox.conf_dir}/#{nameservice}-ehcache.xml"
            source: "#{__dirname}/resources/ehcache.j2"
            local_source: true
            context: nameservice:nameservice

## Master Key

      @call
        header: 'Create Keystore'
        unless_exists: '/usr/hdp/current/knox-server/data/security/master'
        handler: (options, callback) ->
          @options.ssh.shell (err, stream) =>
            stream.write "su -l #{knox.user.name} -c '/usr/hdp/current/knox-server/bin/knoxcli.sh create-master'\n"
            stream.on 'data', (data, extended) ->
              if /Enter master secret/.test data then stream.write "#{knox.ssl.storepass}\n"
              if /Master secret is already present on disk/.test data then callback null, false
              else if /Master secret has been persisted to disk/.test data then callback null, true
            stream.on 'exit', -> callback Error 'Exit before end'

      @call
        header: 'Store Password'
        handler: ->
          # Create alias to store password used in topology
          for alias,password of knox.realm_passwords then do (alias,password) => 
            nameservice=alias.split("-")[0]
            @execute
              cmd: "/usr/hdp/current/knox-server/bin/knoxcli.sh create-alias #{alias} --cluster #{nameservice} --value #{password}"

## SSL

      @call header: 'SSL Server', handler: ->
        tmp_location = "/var/tmp/ryba/knox_ssl"
        @file.download
          source: knox.ssl.cacert
          target: "#{tmp_location}/cacert"
          mode: 0o0600
          shy: true
        @file.download
          source: knox.ssl.cert
          target: "#{tmp_location}/cert"
          mode: 0o0600
          shy: true
        @file.download
          source: knox.ssl.key
          target: "#{tmp_location}/key"
          mode: 0o0600
          shy: true
        @java_keystore_add
          keystore: '/usr/hdp/current/knox-server/data/security/keystores/gateway.jks'
          storepass: knox.ssl.storepass
          caname: "hadoop_root_ca"
          cacert: "#{tmp_location}/cacert"
          key: "#{tmp_location}/key"
          cert: "#{tmp_location}/cert"
          keypass: knox.ssl.keypass
          name: 'gateway-identity'
        @execute
          if: -> @status -1
          cmd: "/usr/hdp/current/knox-server/bin/knoxcli.sh create-alias gateway-identity-passphrase --value #{knox.ssl.keypass}"

Knox use Shiro for LDAP authentication and Shiro cannot be configured for 
unsecure SSL.
With LDAPS, the certificate must be imported into the JRE's keystore for the
client to connect to openldap.

        @java_keystore_add
          keystore: "#{jre_home or java_home}/lib/security/cacerts"
          storepass: 'changeit'
          caname: 'hadoop_root_ca'
          cacert: "#{tmp_location}/cacert"
        @remove
          target: "#{tmp_location}/cacert"
          shy: true
        @remove
          target: "#{tmp_location}/cert"
          shy: true
        @remove
          target: "#{tmp_location}/key"
          shy: true

## Log4j

      @file
        header: 'Log4J Properties'
        target: "#{knox.conf_dir}/gateway-log4j.properties"
        source: "#{__dirname}/resources/gateway-log4j.properties"
        local_source: true
        write: for k, v of knox.log4j
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true

## Ranger HBase Plugin Install

      @call
        if: -> @contexts('ryba/ranger/admin').length > 0
        handler: 'ryba/ranger/plugins/knox/install'

## Dependencies

    builder = require 'xmlbuilder'
