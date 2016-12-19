
# Apache NiFi Install

    module.exports = header: 'NiFi Install', handler: ->
      {nifi} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm} = @config.ryba
      {java_home} = @config.java
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      protocol = if nifi.config.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'

      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Users

      @group nifi.group
      @user nifi.user

## HDP - HDF Cohabitation

hdf-select package conflicts with hdp-select package (both provide /usr/bin/conf-select)
So we must manually force install of hdf-select outside of yum to handle it

      @call header: 'HDP/HDF Cohabitation', handler: ->
        @execute 
          unless_exec: 'yum list installed hdf-select'
          cmd: """
          yumdownloader --destdir=/tmp hdf-select
          rpm -i --replacefiles /tmp/hdf-select*.rpm
          rm -f /tmp/hdf-select*.rpm
          """

## Layout

      @call header: 'Layout', handler: ->
        @mkdir
          target: nifi.log_dir
          uid: nifi.user.name
          gid: nifi.group.name
        @mkdir
          target: '/var/run/nifi'
          uid: nifi.user.name
          gid: nifi.group.name

## IPTables

  | Service    | Port  | Proto  | Parameter                                   |
  |------------|-------|--------|---------------------------------------------|
  | nifi       | 9750  | tcp    | nifi.web.http.port                          |
  | nifi       | 9760  | tcp    | nifi.web.https.port                         |
  | nifi       | 9870  | tcp    | nifi.cluster.node.protocol.port             |
  | nifi       | 9871  | tcp    | nifi.cluster.manager.protocol.port          |


      rules = [
        { chain: 'INPUT', jump: 'ACCEPT', dport: nifi.config.properties["nifi.web.#{protocol}.port"], protocol: 'tcp', state: 'NEW', comment: "NiFi WebUI port" }
      ]
      if nifi.config.properties['nifi.cluster.is.node'] is 'true'
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: nifi.config.properties['nifi.cluster.node.protocol.port'], protocol: 'tcp', state: 'NEW', comment: "NiFi Node port" }
      if nifi.config.properties['nifi.cluster.is.manager'] is 'true'
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: nifi.config.properties['nifi.cluster.manager.protocol.port'], protocol: 'tcp', state: 'NEW', comment: "NiFi Manager port" }
      if nifi.config.properties['nifi.cluster.protocol.use.multicast'] is 'true'
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: nifi.config.properties['nifi.cluster.protocol.multicast.port'], protocol: 'tcp', state: 'NEW', comment: "NiFi Multicast port" }
      if nifi.config.properties['nifi.remote.input.socket.port'] and nifi.config.properties['nifi.remote.input.socket.port'] isnt ''
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: nifi.config.properties['nifi.remote.input.socket.port'], protocol: 'tcp', state: 'NEW', comment: "NiFi S2S RAW socket port" }
      @iptables
        header: 'IPTables'
        if: @config.iptables.action is 'start'
        rules: rules

## Service

      @call header: 'Packages', timeout: -1, handler: ->
        @service
          name: 'nifi'
        @execute
          header: 'fix permissions'
          cmd: """
          chown -R #{nifi.user.name}:#{nifi.group.name} /usr/hdf/current/nifi/lib
          """
          if: -> @status -1
        @chown
          target: '/var/run/nifi'
          uid: nifi.user.name
          gid: nifi.group.name
        @render
          header: 'rc.d'
          target: '/etc/init.d/nifi'
          source: "#{__dirname}/resources/nifi.j2"
          context: @config
          local: true
          mode: 0o0755

## Env

      @render
        header: 'Env'
        target: '/usr/hdf/current/nifi/bin/nifi-env.sh'
        source: "#{__dirname}/resources/nifi-env.sh.j2"
        context:
          java_home: java_home
          nifi: nifi
        local: true
        backup: true

## Keep JAVA_HOME

NiFi service script use sudo to impersonate. Since, sudo must keep JAVA_HOME env
var to work.

      @call header: 'sudo keep JAVA_HOME', handler: ->
        @chmod
          target: '/etc/sudoers'
          mode: 0o640
        @file
          target: '/etc/sudoers'
          write: [
            match: 'Defaults    env_keep += "JAVA_HOME"'
            replace: 'Defaults    env_keep += "JAVA_HOME"'
            place_before: /Defaults +env_keep \+=/
            append: true
          ]
          backup: true

## Login Identity Providers

Describe where to get the user authentication information from.

      @call header: 'Login identity provider', handler: ->
        providers = builder.create('loginIdentityProviders').dec '1.0', 'UTF-8', true 
        {ldap_provider, krb5_provider} = nifi.config.login_providers
        if ldap_provider?
          ldap_node = providers.ele 'provider'
          ldap_node.ele 'identifier', 'ldap-provider'
          ldap_node.ele 'class', 'org.apache.nifi.ldap.LdapProvider'
          ldap_node.ele 'property', name: 'Authentication Strategy', ldap_provider.auth_strategy
          ldap_node.ele 'property', name: 'Manager DN', ldap_provider.manager_dn
          ldap_node.ele 'property', name: 'Manager Password', ldap_provider.manager_pwd
          ldap_node.ele 'property', name: 'TLS - Keystore', ldap_provider.tls_keystore
          ldap_node.ele 'property', name: 'TLS - Keystore Password', ldap_provider.tls_keystore_pwd
          ldap_node.ele 'property', name: 'TLS - Keystore Type', ldap_provider.tls_keystore_type
          ldap_node.ele 'property', name: 'TLS - Truststore', ldap_provider.tls_truststore
          ldap_node.ele 'property', name: 'TLS - Truststore Password', ldap_provider.tls_truststore_pwd
          ldap_node.ele 'property', name: 'TLS - Truststore Type', ldap_provider.tls_truststore_type
          ldap_node.ele 'property', name: 'TLS - Client Auth', ldap_provider.tls_client_auth
          ldap_node.ele 'property', name: 'TLS - Protocol', ldap_provider.tls_truststore_protocol
          ldap_node.ele 'property', name: 'TLS - Shutdown Gracefully', 'false'
          ldap_node.ele 'property', name: 'Referral Strategy', ldap_provider.ref_strategy
          ldap_node.ele 'property', name: 'Connect Timeout', '10 secs'
          ldap_node.ele 'property', name: 'Read Timeout', '10 secs'
          ldap_node.ele 'property', name: 'Url', ldap_provider.url
          ldap_node.ele 'property', name: 'User Search Base', ldap_provider.usr_search_base
          ldap_node.ele 'property', name: 'User Search Filter', ldap_provider.usr_search_filter
          ldap_node.ele 'property', name: 'Authentication Expiration', '12 hours'
        if krb5_provider?
          krb_node = providers.ele 'provider'
          krb_node.ele 'identifier', 'kerberos-provider'
          krb_node.ele 'class', 'org.apache.nifi.kerberos.KerberosProvider'
          krb_node.ele 'property', name: 'Default Realm', nifi.config.login_providers.krb5_provider.realm
          krb_node.ele 'property', name: 'Kerberos Config File', nifi.config.properties['nifi.kerberos.krb5.file']
          krb_node.ele 'property', name: 'Authentication Expiration', '10 hours'
          @krb5_addprinc krb5,
            header: 'Kerberos SPNEGO'
            principal: nifi.config.properties['nifi.kerberos.service.principal']
            keytab: nifi.config.properties['nifi.kerberos.keytab.location']
            randkey: true
          @krb5_addprinc krb5,
            header: 'Kerberos Admin'
            principal: nifi.admin.krb5_principal
            password: nifi.admin.krb5_password
        content = providers.end pretty: true
        @file
          target: nifi.config.properties['nifi.login.identity.provider.configuration.file']
          content: content
          uid: nifi.user.name
          gid: nifi.group.name
          backup: true

## Authorization

      @call header: 'Authorizers', handler: ->
        providers = builder.create('authorizers').dec '1.0', 'UTF-8', true
        {file_provider} = nifi.config.authorizers
        if file_provider?
          file_node = providers.ele 'authorizer'
          file_node.ele 'identifier', 'file-provider'
          file_node.ele 'class', 'org.apache.nifi.authorization.FileAuthorizer'
          file_node.ele 'property', name: 'Authorizations File', file_provider['authorizations_file']
          file_node.ele 'property', name: 'Users File', file_provider['users_file']
          file_node.ele 'property', name: 'Initial Admin Identity', file_provider['initial_admin_identity']
          for node, i in file_provider['nodes_identities']
            file_node.ele 'property', name: "Node Identity #{i+1}", node
          @touch
            target: file_provider['authorizations_file']
            uid: nifi.user.name
            gid: nifi.group.name
          @file
            header: 'initial authorizations file'
            if: -> @status -1
            target: file_provider['authorizations_file']
            content: builder.create('authorizations').dec('1.0', 'UTF-8', true).end pretty: true
            eof: true
          @touch
            target: file_provider['users_file']
            uid: nifi.user.name
            gid: nifi.group.name
          @file
            header: 'initial users file'
            if: -> @status -1
            target: file_provider['users_file']
            content: builder.create('tenants').dec('1.0', 'UTF-8', true).end pretty: true
            eof: true
        @file
          target: nifi.config.properties['nifi.authorizer.configuration.file']
          content: providers.end pretty: true
          uid: nifi.user.name
          gid: nifi.group.name
          backup: true

## Cluster State Provider

Describes where the NiFi server store its internal states.
By default it is a local file, but in cluster mode, it uses zookeeper.

      @call header: 'State providers', handler: ->
        providers = builder.create('stateManagement').dec '1.0', 'UTF-8', true
        local_node = providers.ele 'local-provider'
        local_node.ele 'id', 'local-provider'
        local_node.ele 'class', 'org.apache.nifi.controller.state.providers.local.WriteAheadLocalStateProvider'
        local_node.ele 'property', name: 'Directory', "#{nifi.user.home}/state/local"
        cluster_node = providers.ele 'cluster-provider'
        cluster_node.ele 'id', 'zk-provider'
        cluster_node.ele 'class', 'org.apache.nifi.controller.state.providers.zookeeper.ZooKeeperStateProvider'
        cluster_node.ele 'property', name: 'Connect String', nifi.config.properties['nifi.zookeeper.connect.string']
        cluster_node.ele 'property', name: 'Root Node', nifi.config.properties['nifi.zookeeper.root.node']
        cluster_node.ele 'property', name: 'Session Timeout', '30 seconds'
        cluster_node.ele 'property', name: 'Access Control', 'CreatorOnly'
        content = providers.end pretty: true
        @file
          target: nifi.config.properties['nifi.state.management.configuration.file']
          content: content
          uid: nifi.user.name
          gid: nifi.group.name
          backup: true

## Environment

      @render
        header: 'Bootstrap Conf'
        target: "#{nifi.conf_dir}/bootstrap.conf"
        source: "#{__dirname}/resources/bootstrap.conf.j2"
        context: nifi
        local: true
        eof: true
        backup: true

## JAAS

      @krb5_addprinc krb5,
        header: 'Zookeeper Kerberos'
        principal: nifi.krb5_principal
        randkey: true
        keytab: nifi.krb5_keytab
        uid: nifi.user.name
        gid: nifi.group.name
      @file.jaas
        header: 'Zookeeper JAAS'
        target: "#{nifi.conf_dir}/nifi-zookeeper.jaas"
        content: Client:
          principal: nifi.krb5_principal
          keyTab: nifi.krb5_keytab
        uid: nifi.user.name
        gid: nifi.group.name
        mode: 0o600

## Configuration

      @file.properties
        header: 'NiFi properties'
        target: "#{nifi.conf_dir}/nifi.properties"
        content: nifi.config.properties
        backup: true
        eof: true

## SSL

      @call header: 'SSL', retry: 0, if: (-> nifi.config.properties['nifi.cluster.protocol.is.secure'] is 'true'), handler: ->
        # Client: import certificate to all hosts
        @java_keystore_add
          keystore: nifi.config.properties['nifi.security.truststore']
          storepass: nifi.config.properties['nifi.security.truststorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local: true
        # Server: import certificates, private and public keys to hosts with a server
        @java_keystore_add
          keystore: nifi.config.properties['nifi.security.keystore']
          storepass: nifi.config.properties['nifi.security.keystorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          key: "#{ssl.key}"
          cert: "#{ssl.cert}"
          keypass: nifi.config.properties['nifi.security.keyPasswd']
          name: @config.shortname
          local: true
        @java_keystore_add
          keystore: nifi.config.properties['nifi.security.keystore']
          storepass: nifi.config.properties['nifi.security.keystorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local: true

# Notifications

      @file.download
        header: 'Services Notifications'
        target: "#{nifi.conf_dir}/bootstrap-notification-services.xml"
        source: "#{__dirname}/resources/bootstrap-notification-services.xml"

# Logs

      @render
        header: 'Log Configuration'
        target: "#{nifi.conf_dir}/logback.xml"
        source: "#{__dirname}/resources/logback.xml.j2"
        local: true
        context: nifi

## Additional Libs

      @call header: 'Additional Libs', handler: ->
        for lib in nifi.additional_libs
          @file.download
            target: "/usr/hdf/current/nifi/lib/extras/#{path.basename lib}"
            source: lib
            local: true

# User limits

      @system_limits
        header: 'Ulimit'
        user: nifi.user.name
      , nifi.user.limits

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'
    builder = require 'xmlbuilder'
