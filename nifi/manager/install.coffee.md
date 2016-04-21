
# NiFi Manager Install

    module.exports = header: 'NiFi Manager Install', handler: ->
      {nifi, hadoop_group} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      {java} = @config
      tmp_ssl_location = "/var/tmp/ryba/ssl"
      tmp_archive_location = "/var/tmp/ryba/nifi.tar.gz"
      protocol = if nifi.manager.config.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'

## Users

      @group nifi.group
      @user nifi.user

# IPTables

  | Service    | Port  | Proto  | Parameter                                   |
  |------------|-------|--------|---------------------------------------------|
  | manager    | 9750  | tcp    | nifi.web.http.port                          |
  | manager    | 9760  | tcp    | nifi.web.https.port                         |
  | manager    | 9770  | tcp    | nifi.cluster.manager.protocol.port          |
  | manager    | 9780  | tcp    | config.authority_providers.cluster_node.port|
      
      @iptables
        header: 'IPTables'
        if: @config.iptables.action is 'start'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: nifi.manager.config.properties["nifi.web.#{protocol}.port"], protocol: 'tcp', state: 'NEW', comment: "NiFi Web ui port" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nifi.manager.config.properties['nifi.cluster.manager.protocol.port'], protocol: 'tcp', state: 'NEW', comment: "NiFi admin port" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nifi.manager.config.authority_providers.ncm_port, protocol: 'tcp', state: 'NEW', comment: "NiFi manager auth port" }
        ]
    
      @call header: 'Preinstall Layout', handler: ->
          @mkdir
            destination: nifi.manager.install_dir
          @mkdir
            destination: nifi.manager.conf_dir
          @mkdir
            destination: nifi.manager.log_dir
            uid: nifi.user.name
            gid: nifi.group.name

      @call 
        header: 'Packages'
        timeout:-1
        unless_exec: "grep 'nifi.version=#{nifi.version}' #{nifi.manager.install_dir}/#{nifi.version}/conf/nifi.properties"
        handler: ->
          @mkdir
            destination: "#{nifi.manager.install_dir}/#{nifi.version}"
          @download
            source: nifi.source
            destination: tmp_archive_location
          @extract
            source: tmp_archive_location
            destination: "#{nifi.manager.install_dir}/#{nifi.version}"
            preserve_owner: false
            strip: 1
          @remove
            destination: tmp_archive_location

      @call 
        header: 'Postinstall Layout'
        timeout:-1
        handler: ->
          @link
            source: "#{nifi.manager.install_dir}/#{nifi.version}"
            destination: "#{nifi.manager.install_dir}/current"
          # set current version to downloaded version (to support upgrades)
          @remove 
            destination: "#{nifi.manager.install_dir}/current/conf"
            if_exec: "test -d #{nifi.manager.install_dir}/current/conf"
          @link
            source: nifi.manager.conf_dir
            destination: "#{nifi.manager.install_dir}/current/conf"
          @remove 
            destination: "#{nifi.manager.install_dir}/current/logs"
            if_exec: "test -d #{nifi.manager.install_dir}/current/logs"
          @link
            source: nifi.manager.log_dir
            destination: "#{nifi.user.home}/logs"
          # needs to have read/write privileges to load Nar bundles
          @execute
            cmd: "chmod 777 -R  #{nifi.manager.install_dir}/current/lib"
          @render
            destination: '/etc/init.d/nifi-manager'
            source: "#{__dirname}/resources/nifi-manager.j2"
            local_source: true
            context: @config
            mode: 0o0755
          # https://github.com/apache/nifi/blob/master/nifi-bootstrap/src/main/java/org/apache/nifi/bootstrap/RunNiFi.java#L335
          # enable nifi to create pid file in nifi.home/bin directory
          @chown
            destination: "#{nifi.manager.install_dir}/current/bin"
            uid: nifi.user.name
            gid: nifi.group.name

## Login Identity Providers

Describe where to get the user athentication onformation from.

      @call header: 'Login identity provider', handler: ->
        providers = builder.create('loginIdentityProviders').dec '1.0', 'UTF-8', true 
        {ldap_provider, krb5_provider} = nifi.manager.config.providers
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
          krb_node.ele 'property', name: 'Default Realm', krb5_provider['realm']
          krb_node.ele 'property', name: 'Kerberos Config File', krb5_provider['file']
          krb_node.ele 'property', name: 'Authentication Expiration', '12 hours'
        content = providers.end pretty: true
        @write
          header: 'Login Identity Provider'
          # source: "#{__dirname}/../resources/login-identity-providers.xml.j2"
          destination: "#{nifi.manager.conf_dir}/login-identity-providers.xml"
          content: content
          local_source: true
          uid: nifi.user.name
          gid: nifi.group.name
          backup: true
          mode: 0o0755


## Authorized Users

Set up different users to be able to access the NiFi Web ui

      @call header: 'Authorized Users', handler: ->
        users = builder.create('users').dec '1.0', 'UTF-8', true 
        for a_user in nifi.manager.config.authorized_users
          user = users.ele 'user'
          user.att 'dn', a_user['dn']
          for a_role in a_user['roles']
            role = user.ele 'role', 'name': "#{a_role}"
        content = users.end pretty:true
        @write
          destination: "#{nifi.manager.conf_dir}/authorized-users.xml"
          local_source: true
          content: content
          uid: nifi.user.name
          gid: nifi.group.name
          backup: true
          mode: 0o0755

## Cluster Manager authority provider

Sets niFi server to get credentials from the cluster manager
Not sure we need it on the Manager.
      
      @render
        header: 'Authority Providers'
        source: "#{__dirname}/../resources/authority-providers.xml.j2"
        destination: "#{nifi.manager.conf_dir}/authority-providers.xml"
        context: nifi.manager
        local_source: true
        uid: nifi.user.name
        gid: nifi.group.name
        backup: true
        eof: true
        mode: 0o0755

## Cluster State Provider

Describes where the NiFi server store its internal states.
By default it is a local file, but in cluster mode, it uses zookeeper.
          
      @render
        header: 'State Provider'
        source: "#{__dirname}/../resources/state-management.xml.j2"
        destination: "#{nifi.manager.conf_dir}/state-management.xml"
        context: @config.ryba
        local_source: true
        uid: nifi.user.name
        gid: nifi.group.name
        backup: true
        mode: 0o0755

      @krb5_addprinc
        header: 'Kerberos'
        principal: nifi.manager.krb5_principal
        randkey: true
        keytab: nifi.manager.krb5_keytab
        uid: nifi.user.name
        gid: nifi.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
        
      @krb5_addprinc
        if: nifi.manager.config.properties['nifi.security.user.login.identity.provider'] is 'kerberos-provider'
        header: 'Kerberos NiFi Web UI Manager'
        principal: nifi.webui.krb5_principal
        password: nifi.webui.krb5_password
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
    
## Environment

Need to manually set `-Djavax.net.ssl.trustStore` and `-Djavax.net.ssl.trustStorePassword`
to specify to fix `PKIX path building failed` when the Manager server validates user's credentials
by sending request to ldaps server

      @render
        header: 'Bootstrap Conf'
        source: "#{__dirname}/../resources/bootstrap.conf.j2"
        destination: "#{nifi.manager.conf_dir}/bootstrap.conf"
        eof: true
        backup: true
        context:
          java_opts: nifi.manager.java_opts
          user: nifi.user
          conf_dir: nifi.manager.conf_dir
          install_dir: nifi.manager.install_dir
        local_source: true

## JAAS

      @write_jaas
        header: 'Zookeeper JAAS'
        destination: "#{nifi.manager.conf_dir}/nifi-zookeeper.jaas"
        content: Client:
          principal: nifi.manager.krb5_principal
          keyTab: nifi.manager.krb5_keytab
        uid: nifi.user.name
        gid: nifi.group.name
        mode: 0o700

## Configuration  

      @render
        header: 'Server properties'
        source: "#{__dirname}/../resources/nifi.properties"
        destination: "#{nifi.manager.conf_dir}/nifi.properties"
        local_source: true
        write: for k, v of nifi.manager.config.properties
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

      @call header: 'SSL', retry: 0, handler: ->
        # Client: import certificate to all hosts
        @java_keystore_add
          keystore: nifi.manager.config.properties['nifi.security.truststore']
          storepass: nifi.manager.config.properties['nifi.security.truststorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true
        # Server: import certificates, private and public keys to hosts with a server
        @java_keystore_add
          keystore: nifi.manager.config.properties['nifi.security.keystore']
          storepass: nifi.manager.config.properties['nifi.security.keystorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          key: "#{ssl.key}"
          cert: "#{ssl.cert}"
          keypass: nifi.manager.config.properties['nifi.security.keyPasswd']
          name: @config.shortname
          local_source: true
        @java_keystore_add
          keystore: nifi.manager.config.properties['nifi.security.keystore']
          storepass: nifi.manager.config.properties['nifi.security.keystorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true

# Notifications

      @download
        header: 'Services Notifications'
        destination: "#{nifi.manager.conf_dir}/bootstrap-notification-services.xml"
        source: "#{__dirname}/../resources/bootstrap-notification-services.xml"

# Logs
 
      @render
        header: 'Log Configuration'
        destination: "#{nifi.manager.conf_dir}/logback.xml"
        source: "#{__dirname}/../resources/logback.xml.j2"
        local_source: true
        context: nifi.manager

# User limits

      @system_limits
        user: nifi.user.name
        nofile: nifi.user.limits.nofile
        nproc: nifi.user.limits.nproc

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'
    builder = require 'xmlbuilder'
