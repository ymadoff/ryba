
## Apache NiFi Manager Configure

    module.exports = ->
      openldap_servers = @contexts 'masson/core/openldap_server'
      zk_hosts = @contexts 'ryba/zookeeper/server'
      {nifi, realm} = @config.ryba
      nifi.manager  ?= {}
      nifi.manager.install_dir ?= "#{nifi.root_dir}/nifi-manager"
      nifi.manager.conf_dir ?= '/etc/nifi-manager/conf'
      nifi.manager.log_dir ?= '/var/log/nifi'
      nifi.webui ?= {}
      config = nifi.manager.config ?= {}
      properties = config.properties ?= {}
      #version
      properties['nifi.version'] ?= "#{nifi.version}"

## Security

      properties['nifi.kerberos.krb5.file'] ?= '/etc/krb5.conf' if @config.ryba.security is 'kerberos'
      properties['nifi.cluster.protocol.is.secure'] ?= 'true'
      properties['nifi.web.http.port'] ?= '9750'
      properties['nifi.web.https.host'] ?= "#{@config.host}"
      properties['nifi.web.https.port'] ?= '9760'
      # NiFi does not perform user authentication over HTTP.
      # Using HTTP all users will be granted all roles.
      if properties['nifi.cluster.protocol.is.secure'] is 'true'
        properties['nifi.web.http.port'] = null
        properties['nifi.security.keystore'] ?= "#{nifi.manager.conf_dir}/keystore"
        properties['nifi.security.keystoreType'] ?= 'JKS'
        properties['nifi.security.keystorePasswd'] ?= 'nifi123'
        properties['nifi.security.keyPasswd'] ?= 'nifi123'
        properties['nifi.security.truststore'] ?= "#{nifi.manager.conf_dir}/truststore"
        properties['nifi.security.truststoreType'] ?= 'JKS'
        properties['nifi.security.truststorePasswd'] ?= 'nifi123'
        # This indicates whether a secure NiFi is configured to allow users to request access
        properties['nifi.security.support.new.account.requests'] ?= 'true'
        properties['nifi.security.needClientAuth'] ?= 'true'
        # Valid Authorities include: ROLE_MONITOR,ROLE_DFM,ROLE_ADMIN,ROLE_PROVENANCE,ROLE_NIFI
        # role given to anonymous users
        properties['nifi.security.anonymous.authorities'] ?= '' # no role given to anonymous
        # secure inner connection and remote
        properties['nifi.remote.input.secure'] ?= 'true'

## User Authentication And Authorization

Starting from 0.6.0
NiFi has three native way for prividing user authentication.
- Client certificates
- Using an LDAP server
- Using a kerberos server
Only the seconds and third methods provides a login/password method.

When authentication is enabled NiFi requires to manually set up an auhtorized user to first connect
to the web ui and create the other users. This is done by providing authorized-user.xml file

If ldap-provider is enabled Ryba will first check if ldap connection properties are defined cluster wide. In no props are found
it will look for installed `masson/core/openldap_server` module and configuration.

Note: Authentication is done only over https protocol, `nifi.cluster.protocol.is.secure` set to true.

ACL are managed by the authorized-user.xml file. It supports configuration for several users.
NiFi needs at least one user configured with ROLE_ADMIN to be able to manage users.
The clients request access to nifi, and admin accepts/denies request to webui

        properties['nifi.security.user.login.identity.provider'] ?= 'kerberos-provider'
        properties['nifi.login.identity.provider.configuration.file'] ?= "#{nifi.manager.conf_dir}/login-identity-providers.xml"
        config.providers ?= {}
        switch properties['nifi.security.user.login.identity.provider']
          when 'ldap-provider'
            ldap_provider = config.providers['ldap_provider'] ?= {}
            ldap_provider['auth_strategy'] ?= 'SIMPLE'
            ldap_provider['tls_keystore'] ?= "#{properties['nifi.security.keystore']}"
            ldap_provider['tls_keystore_pwd'] ?= "#{properties['nifi.security.keystorePasswd']}"
            ldap_provider['tls_keystore_type'] ?= "#{properties['nifi.security.keystoreType']}"
            ldap_provider['tls_truststore'] ?= "#{properties['nifi.security.truststore']}"
            ldap_provider['tls_truststore_pwd'] ?= "#{properties['nifi.security.truststorePasswd']}"
            ldap_provider['tls_truststore_type'] ?= "#{properties['nifi.security.truststoreType']}"
            ldap_provider['tls_truststore_protocol'] ?= 'TLS'
            ldap_provider['tls_client_auth'] ?= 'NONE'
            ldap_provider['ref_strategy'] ?= 'FOLLOW'
            unless ldap_provider['manager_dn']?
              [openldap_server_ctx] = openldap_servers
              throw Error 'no openldap server configured' unless openldap_server_ctx?
              {openldap_server} = openldap_server_ctx.config
              ldap_provider['manager_dn'] ?= "#{openldap_server.root_dn}"
              ldap_provider['manager_pwd'] ?= "#{openldap_server.root_password}"
              ldap_provider['url'] ?= 'ldaps://master3.ryba:636'
              ldap_provider['usr_search_base'] ?= 'ou=users,dc=ryba'
              ldap_provider['usr_search_filter'] ?= 'uid={0}'#'ou=groups,dc=ryba'
              config.authorized_users ?= [
                dn: "#{openldap_server.root_dn}"
                roles: ['ROLE_ADMIN']
              ]
          when 'kerberos-provider'
            [a,b] = nifi.version.split('.')
            throw Error 'kerberos Provider only support from 0.6.0 version ' if  a is '0' and parseInt(b) < 6
            # /nifi-0.6.0/docs/html/administration-guide.html#kerberos_properties
            krb5_provider = config.providers['krb5_provider'] ?= {}
            krb5_provider['file'] ?= '/etc/krb5.conf'
            krb5_provider['realm'] ?= "#{realm}"
            properties['nifi.kerberos.krb5.file'] ?= krb5_provider['file']
            properties['nifi.kerberos.service.principal'] ?= "HTTP/#{@config.host}@#{realm}"
            properties['nifi.kerberos.keytab.location'] ?= '/etc/security/keytabs/spnego.service.keytab'
            nifi.webui.krb5_principal ?= "#{nifi.user.name}@#{realm}"
            nifi.webui.krb5_password ?= 'nifi123'
            config.authorized_users ?= [
              dn: "#{nifi.webui.krb5_principal}"
              roles: ['ROLE_ADMIN']
            ]
          else
            throw Error 'login provider is not supported'
        throw Error 'No admin user configured for NiFi webUI' unless config.authorized_users?

## Cluster Configuration

Different type of properties has to be set:
- How NiFi Master(manager) and Slaves(nodes) communicates (port binding).
- Where Authentication take places for master/slaves (and ACLs)
- Where to store states of the cluster

      # required property to define the server as a master role
      properties['nifi.cluster.is.manager'] ?= 'true'
      # Defines the port where manager will be accessible to communicate with nodes
      properties['nifi.cluster.manager.address'] ?= "#{@config.host}"
      properties['nifi.cluster.manager.protocol.port'] ?= '9770'
      # ACLS
      # In a secured cluster, the authentication takes place on the niFi master server.
      # The authority-providers files has to provisionned for both `cluster-ncm-provider` (for the manager)
      # and `cluster-node-provider` for each nodes.
      properties['nifi.security.user.authority.provider'] ?= 'cluster-ncm-provider'
      properties['nifi.authority.provider.configuration.file'] ?= "#{nifi.manager.conf_dir}/authority-providers.xml" # External file describing conf
      # A port must be defined for the authentication part
      config.authority_providers ?= {}
      config.authority_providers.ncm_port ?= '9780'
      # State provider
      # Defines how and where niFi servers stores states about nodes.
      properties['nifi.state.management.provider.local'] ?= 'local-provider' # present by default
      properties['nifi.state.management.configuration.file'] ?= "#{nifi.manager.conf_dir}/state-management.xml" # External file describing conf
      # NiFi support only zookeeper as cluster wide state provider
      # NiFi can use an embbed zookeeper nifi.state.management.embedded.zookeeper.start is set to true
      # We support only external zookeeper quorum
      properties['nifi.state.management.provider.cluster'] ?= 'zk-provider'
      switch properties['nifi.state.management.provider.cluster']
        when 'zk-provider'
          throw Error 'No zookeeper quorum configured' unless zk_hosts.length
          nifi.zk_connect ?= zk_hosts.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
          nifi.zk_node ?= '/nifi'
          # used for nifi to authenticate to kerberos sucurized zookeeper ensemble
          if @config.ryba.security is 'kerberos'
            nifi.manager.krb5_principal ?=  "#{nifi.user.name}_manager/#{@config.host}@#{realm}"
            nifi.manager.krb5_keytab ?=  '/etc/security/keytabs/nifi.manager.service.keytab'
        else
          throw Error 'No other cluster state provider is supported for now'

# Core Properties #

      properties['nifi.flow.configuration.file'] ?= "#{nifi.user.home}/flow.xml.gz"
      properties['nifi.flow.configuration.archive.dir'] ?= "#{nifi.user.home}/archive/"
      properties['nifi.flowfile.repository.directory'] ?= "#{nifi.user.home}/flowfile_repository"
      properties['nifi.templates.directory'] ?= "#{nifi.user.home}/templates"
      properties['nifi.nar.library.directory'] ?= "#{nifi.manager.install_dir}/current/lib"
      properties['nifi.nar.working.directory'] ?= "#{nifi.user.home}/work/nar/"
      properties['nifi.documentation.working.directory'] ?= "#{nifi.user.home}/work/docs/components"
      # H2 Settings
      properties['nifi.database.directory'] ?= "#{nifi.user.home}/database_repository"
      # Content Repository
      properties['nifi.content.repository.directory.default'] ?= "#{nifi.user.home}/content_repository"
      # Persistent Provenance Repository Properties
      properties['nifi.provenance.repository.directory.default'] ?= "#{nifi.user.home}/provenance_repository"
      # web properties #
      properties['nifi.web.war.directory'] ?= "#{nifi.manager.install_dir}/current/lib"
      properties['nifi.web.jetty.working.directory'] ?= "#{nifi.user.home}/work/jetty"

## JAVA Opts

      #nifi-0.6.0/docs/html/administration-guide.html#bootstrap_properties
      nifi.manager.java_opts ?= {}
      nifi.manager.java_opts['ReservedCodeCacheSize'] ?= '256m'
      nifi.manager.java_opts['CodeCacheFlushingMinimumFreeSpace'] ?= '10m'
      nifi.manager.java_opts['permsize'] ?= '128m'
      nifi.manager.java_opts['maxpermsize'] ?= '256m'

[hdp-nifi]:(https://docs.hortonworks.com/HDPDocuments/HDF1/HDF-1.1.0/bk_AdminGuide/content/ch_AdminGuide.html)
[cluster-migration]:(https://community.hortonworks.com/articles/9203/how-to-migrate-a-standalone-nifi-into-a-nifi-clust.html)
[example-nifi]:(https://community.hortonworks.com/articles/7341/nifi-user-authentication-with-ldap.html)
