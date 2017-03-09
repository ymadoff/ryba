
# NiFi Configure

    module.exports = ->
      nifi = @config.ryba.nifi ?= {}
      # Set it to true if both hdf and hdp are installed on the cluster
      @config.ryba.hdf_hdp ?= false
      nifi.conf_dir ?= '/etc/nifi/conf'
      nifi.log_dir ?= '/var/log/nifi'
      zk_hosts = @contexts('ryba/zookeeper/server').filter( (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant')

## User and Groups

      # User
      nifi.user = name: nifi.user if typeof nifi.user is 'string'
      nifi.user ?= {}
      nifi.user.name ?= 'nifi'
      nifi.user.system ?= true
      nifi.user.comment ?= 'NiFi User'
      nifi.user.home ?= '/var/lib/nifi'
      # Group
      nifi.group = name: nifi.group if typeof nifi.group is 'string'
      nifi.group ?= {}
      nifi.group.name ?= 'nifi'
      nifi.group.system ?= true
      nifi.user.limits ?= {}
      nifi.user.limits.nofile ?= 64000
      nifi.user.limits.nproc ?= 10000
      nifi.user.gid = nifi.group.name
      nifi.config ?= {}
      properties = nifi.config.properties ?= {}

## Core Properties

      properties['nifi.version'] ?= '1.0.0.2.0.1.0-12'
      properties['nifi.flow.configuration.file'] ?= "#{nifi.user.home}/flow.xml.gz"
      properties['nifi.flow.configuration.archive.dir'] ?= "#{nifi.user.home}/archive"
      properties['nifi.flowcontroller.autoResumeState'] ?= 'true'
      properties['nifi.flowcontroller.graceful.shutdown.period'] ?= '10 sec'
      properties['nifi.flowservice.writedelay.interval'] ?= '500 ms'
      properties['nifi.administrative.yield.duration'] ?= '30 sec'
      # If a component has no work to do (is "bored"), how long should we wait before checking again for work?'
      properties['nifi.bored.yield.duration'] ?= '10 millis'

      properties['nifi.authorizer.configuration.file'] ?= "#{nifi.conf_dir}/authorizers.xml"
      properties['nifi.login.identity.provider.configuration.file'] ?= "#{nifi.conf_dir}/login-identity-providers.xml"
      properties['nifi.templates.directory'] ?= "#{nifi.user.home}/templates"
      properties['nifi.ui.banner.text'] ?= ''
      properties['nifi.ui.autorefresh.interval'] ?= '30 sec'
      properties['nifi.nar.library.directory'] ?= '/usr/hdf/current/nifi/lib'
      properties['nifi.nar.working.directory'] ?= "#{nifi.user.home}/work/nar/"
      properties['nifi.documentation.working.directory'] ?= "#{nifi.user.home}/work/docs/components"

## State Management

      properties['nifi.state.management.configuration.file'] ?= "#{nifi.conf_dir}/state-management.xml"
      # The ID of the local state provider
      properties['nifi.state.management.provider.local'] ?= 'local-provider'
      # The ID of the cluster-wide state provider. This will be ignored if NiFi is not clustered but must be populated if running in a cluster.
      properties['nifi.state.management.provider.cluster'] ?= 'zk-provider'
      # Specifies whether or not this instance of NiFi should run an embedded ZooKeeper server
      properties['nifi.state.management.embedded.zookeeper.start'] ?= 'false'
      # Properties file that provides the ZooKeeper properties to use if <nifi.state.management.embedded.zookeeper.start> is set to true
      properties['nifi.state.management.embedded.zookeeper.properties'] ?= "#{nifi.conf_dir}/zookeeper.properties"

## H2 Settings

      properties['nifi.database.directory'] ?= "#{nifi.user.home}/database_repository"
      properties['nifi.h2.url.append'] ?= ';LOCK_TIMEOUT=25000;WRITE_DELAY=0;AUTO_SERVER=FALSE'

## Flow Configuration

      properties['nifi.flow.configuration.archive.enabled'] ?= 'true'
      properties['nifi.flow.configuration.archive.max.time'] ?= '30 days'
      properties['nifi.flow.configuration.archive.max.storage'] ?= '500 MB'
      # FlowFile Repository
      properties['nifi.flowfile.repository.implementation'] ?= 'org.apache.nifi.controller.repository.WriteAheadFlowFileRepository'
      properties['nifi.flowfile.repository.directory'] ?= "#{nifi.user.home}/flowfile_repository"
      properties['nifi.flowfile.repository.partitions'] ?= '256'
      properties['nifi.flowfile.repository.checkpoint.interval'] ?= '2 mins'
      properties['nifi.flowfile.repository.always.sync'] ?= 'false'

## Swap Configuration

      properties['nifi.swap.manager.implementation'] ?= 'org.apache.nifi.controller.FileSystemSwapManager'
      properties['nifi.queue.swap.threshold'] ?= '20000'
      properties['nifi.swap.in.period'] ?= '5 sec'
      properties['nifi.swap.in.threads'] ?= '1'
      properties['nifi.swap.out.period'] ?= '5 sec'
      properties['nifi.swap.out.threads'] ?= '4'

## Content Configuration

      properties['nifi.content.repository.implementation'] ?= 'org.apache.nifi.controller.repository.FileSystemRepository'
      properties['nifi.content.repository.directory.default'] ?= "#{nifi.user.home}/content_repository"
      properties['nifi.content.claim.max.appendable.size'] ?= '10 MB'
      properties['nifi.content.claim.max.flow.files'] ?= '100'
      properties['nifi.content.repository.archive.max.retention.period'] ?= '12 hours'
      properties['nifi.content.repository.archive.max.usage.percentage'] ?= '50%'
      properties['nifi.content.repository.archive.enabled'] ?= 'true'
      properties['nifi.content.repository.always.sync'] ?= 'false'
      properties['nifi.content.viewer.url'] ?= '/nifi-content-viewer/'

## Provenance Configuration

      properties['nifi.provenance.repository.implementation'] ?= 'org.apache.nifi.provenance.PersistentProvenanceRepository'
      properties['nifi.provenance.repository.directory.default'] ?= "#{nifi.user.home}/provenance_repository"
      properties['nifi.provenance.repository.max.storage.time'] ?= '24 hours'
      properties['nifi.provenance.repository.max.storage.size'] ?= '1 GB'
      properties['nifi.provenance.repository.rollover.time'] ?= '30 secs'
      properties['nifi.provenance.repository.rollover.size'] ?= '100 MB'
      properties['nifi.provenance.repository.query.threads'] ?= '2'
      properties['nifi.provenance.repository.index.threads'] ?= '1'
      properties['nifi.provenance.repository.compress.on.rollover'] ?= 'true'
      properties['nifi.provenance.repository.always.sync'] ?= 'false'
      properties['nifi.provenance.repository.journal.count'] ?= '16'
      # Comma-separated list of fields. Fields that are not indexed will not be searchable. Valid fields are: 
      # EventType, FlowFileUUID, Filename, TransitURI, ProcessorID, AlternateIdentifierURI, Relationship, Details
      properties['nifi.provenance.repository.indexed.fields'] ?= 'EventType, FlowFileUUID, Filename, ProcessorID, Relationship'
      # FlowFile Attributes that should be indexed and made searchable.  Some examples to consider are filename, uuid, mime.type
      properties['nifi.provenance.repository.indexed.attributes'] ?= ''
      # Large values for the shard size will result in more Java heap usage when searching the Provenance Repository
      # but should provide better performance
      properties['nifi.provenance.repository.index.shard.size'] ?= '500 MB'
      # Indicates the maximum length that a FlowFile attribute can be when retrieving a Provenance Event from
      # the repository. If the length of any attribute exceeds this value, it will be truncated when the event is retrieved.
      properties['nifi.provenance.repository.max.attribute.length'] ?= '65536'
      # Volatile Provenance Respository Properties
      properties['nifi.provenance.repository.buffer.size'] ?= '100000'

## Component Status Repository

      properties['nifi.components.status.repository.implementation'] ?= 'org.apache.nifi.controller.status.history.VolatileComponentStatusRepository'
      properties['nifi.components.status.repository.buffer.size'] ?= '1440'
      properties['nifi.components.status.snapshot.frequency'] ?= '1 min'

## Site to site properties

      properties['nifi.remote.input.socket.host'] ?= @config.host
      # Set a specific port in order to use RAW socket as transport protocol for Site-to-Site
      properties['nifi.remote.input.socket.port'] ?= ''

## Web Properties

      properties['nifi.web.war.directory'] ?= '/usr/hdf/current/nifi/lib'
      properties['nifi.web.jetty.working.directory'] ?= "#{nifi.user.home}/work/jetty"
      properties['nifi.web.jetty.threads'] ?= '200'

## Common Properties

      # cluster common properties (cluster manager and nodes must have same values) #
      properties['nifi.cluster.protocol.heartbeat.interval'] ?= '5 sec'
      properties['nifi.cluster.protocol.socket.timeout'] ?= '30 sec'
      properties['nifi.cluster.protocol.connection.handshake.timeout'] ?= '45 sec'
      # if multicast is used, then nifi.cluster.protocol.multicast.xxx properties must be configured #
      properties['nifi.cluster.protocol.use.multicast'] ?= 'false'
      properties['nifi.cluster.protocol.multicast.address'] ?= ''
      properties['nifi.cluster.protocol.multicast.port'] ?= '9872'
      properties['nifi.cluster.protocol.multicast.service.broadcast.delay'] ?= '500 ms'
      properties['nifi.cluster.protocol.multicast.service.locator.attempts'] ?= '3'
      properties['nifi.cluster.protocol.multicast.service.locator.attempts.delay'] ?= '1 sec'
      # cluster node properties (only configure for cluster nodes) #
      properties['nifi.cluster.is.node'] ?= 'true'
      if properties['nifi.cluster.is.node'] is 'true'
        properties['nifi.cluster.node.address'] ?= @config.host
        properties['nifi.cluster.node.protocol.port'] ?= '9870'
        properties['nifi.cluster.node.protocol.threads'] ?= '2'
        properties['nifi.zookeeper.connect.string'] ?= zk_hosts.map( (ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
        properties['nifi.zookeeper.root.node'] ?= '/nifi'
        properties['nifi.cluster.request.replication.claim.timeout'] ?= '15 sec'
      properties['nifi.cluster.is.manager'] ?= 'false'
      if properties['nifi.cluster.is.manager'] is 'true'
        properties['nifi.cluster.manager.address'] ?= @config.host
        properties['nifi.cluster.manager.protocol.port'] ?= '9871'
        properties['nifi.cluster.manager.node.firewall.file'] ?= ''
        properties['nifi.cluster.manager.node.event.history.size'] ?= '10'
        properties['nifi.cluster.manager.node.api.connection.timeout'] ?= '30 sec'
        properties['nifi.cluster.manager.node.api.read.timeout'] ?= '30 sec'
        properties['nifi.cluster.manager.node.api.request.threads'] ?= '10'
        properties['nifi.cluster.manager.flow.retrieval.delay'] ?= '5 sec'
        properties['nifi.cluster.manager.protocol.threads'] ?= '10'
        properties['nifi.cluster.manager.safemode.duration'] ?= '0 sec'

## Security

      #Sensitive value encryption
      properties['nifi.sensitive.props.key'] ?= '' #'nifi_master_secret_123'
      properties['nifi.sensitive.props.algorithm'] ?= 'PBEWITHMD5AND256BITAES-CBC-OPENSSL'
      properties['nifi.sensitive.props.provider'] ?= 'BC'
      # Kerberos
      properties['nifi.kerberos.krb5.file'] ?= '/etc/krb5.conf' if @config.ryba.security is 'kerberos'
      # SSL
      properties['nifi.cluster.protocol.is.secure'] ?= 'true'
      if properties['nifi.cluster.protocol.is.secure'] is 'true'
        properties['nifi.web.http.host'] = ''
        properties['nifi.web.http.port'] = ''
        properties['nifi.web.https.host'] ?= @config.host
        properties['nifi.web.https.port'] ?= '9760'
        properties['nifi.security.keystore'] ?= "#{nifi.conf_dir}/keystore"
        properties['nifi.security.keystoreType'] ?= 'JKS'
        properties['nifi.security.keystorePasswd'] ?= 'nifi123'
        properties['nifi.security.keyPasswd'] ?= 'nifi123'
        properties['nifi.security.truststore'] ?= "#{nifi.conf_dir}/truststore"
        properties['nifi.security.truststoreType'] ?= 'JKS'
        properties['nifi.security.truststorePasswd'] ?= 'nifi123'
        properties['nifi.security.needClientAuth'] ?= 'true'
        # Valid Authorities include: ROLE_MONITOR,ROLE_DFM,ROLE_ADMIN,ROLE_PROVENANCE,ROLE_NIFI
        # role given to anonymous users
        properties['nifi.security.anonymous.authorities'] ?= '' # no role given to anonymous
        # secure inner connection and remote
        properties['nifi.remote.input.secure'] ?= 'true'
      else
        properties['nifi.web.http.host'] ?= @config.host
        properties['nifi.web.http.port'] ?= '9750'
        properties['nifi.web.https.host'] = ''
        properties['nifi.web.https.port'] = ''

## User Authentication

      properties['nifi.security.user.login.identity.provider'] ?= 'kerberos-provider'
      properties['nifi.login.identity.provider.configuration.file'] ?= "#{nifi.conf_dir}/login-identity-providers.xml"
      nifi.config.login_providers ?= {}
      switch properties['nifi.security.user.login.identity.provider']
        when 'ldap-provider'
          ldap_provider = nifi.config.login_providers.ldap_provider ?= {}
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
            [openldap_server_ctx] = @contexts 'masson/core/openldap_server'
            throw Error 'no openldap server configured' unless openldap_server_ctx?
            {openldap_server} = openldap_server_ctx.config
            ldap_provider['manager_dn'] ?= "#{openldap_server.root_dn}"
            ldap_provider['manager_pwd'] ?= "#{openldap_server.root_password}"
            ldap_provider['url'] ?= "#{openldap_server.uri}:636"
            ldap_provider['usr_search_base'] ?= openldap_server.users_dn
            ldap_provider['usr_search_filter'] ?= 'uid={0}'#'ou=groups,dc=ryba'
        when 'kerberos-provider'
          krb5_provider = nifi.config.login_providers.krb5_provider ?= {}
          krb5_provider['realm'] ?= @config.ryba.realm
          properties['nifi.kerberos.service.principal'] ?= "HTTP/#{@config.host}@#{@config.ryba.realm}"
          properties['nifi.kerberos.keytab.location'] ?= '/etc/security/keytabs/spnego.service.keytab'
          nifi.admin ?= {}
          nifi.admin.krb5_principal ?= "#{nifi.user.name}@#{@config.ryba.realm}"
          nifi.admin.krb5_password ?= 'nifi123'
        else
          throw Error 'login provider is not supported'
      properties['nifi.security.identity.mapping.pattern.dn'] ?= '^CN=(.*?),(.*)$'
      properties['nifi.security.identity.mapping.value.dn'] ?= '$1'
      properties['nifi.security.identity.mapping.pattern.kerb'] ?= '^(.*?)@(.*?)$'
      properties['nifi.security.identity.mapping.value.kerb'] ?= '$1'

## User Authorization

      properties['nifi.authorizer.configuration.file'] ?= "#{nifi.conf_dir}/authorizers.xml"
      properties['nifi.security.user.authorizer'] ?= 'file-provider'
      nifi.config.authorizers ?= {}
      switch properties['nifi.security.user.authorizer']
        when 'file-provider'
          file_provider = nifi.config.authorizers.file_provider ?= {}
          file_provider['authorizations_file'] ?= "#{nifi.conf_dir}/authorizations.xml"
          file_provider['users_file'] ?= "#{nifi.conf_dir}/users.xml"
          file_provider['initial_admin_identity'] ?= nifi.user.name
          file_provider['nodes_identities'] ?= @contexts('ryba/nifi').map((ctx) -> ctx.config.host)
        else
          throw Error 'Authorizer is not supported'

## Cluster Management

      switch properties['nifi.state.management.provider.cluster']
        when 'zk-provider'
          throw Error 'No zookeeper quorum configured' unless zk_hosts.length
          # used for nifi to authenticate to kerberos sucurized zookeeper ensemble
          if @config.ryba.security is 'kerberos'
            nifi.krb5_principal ?=  "#{nifi.user.name}/#{@config.host}@#{@config.ryba.realm}"
            nifi.krb5_keytab ?=  '/etc/security/keytabs/nifi.service.keytab'
        else
          throw Error 'No other cluster state provider is supported for now'

## Java Opts

      nifi.java_opts ?= [
        '-Dorg.apache.jasper.compiler.disablejsr199=true'
        '-Xms512m'
        '-Xmx512m'
        '-Djava.net.preferIPv4Stack=true'
        '-Dsun.net.http.allowRestrictedHeaders=true'
        '-Djava.protocol.handler.pkgs=sun.net.www.protocol'
        '-XX:+UseG1GC'
        '-Djava.awt.headless=true'
        "-Djava.security.auth.login.config=#{nifi.conf_dir}/nifi-zookeeper.jaas"
      ]

## Additional Libs

Set local path of additional libs (for custom processors) in this array.

      nifi.additional_libs ?= []

## Data Directories Layout

      props = Object.keys(properties).filter (prop) ->
       prop.indexOf('nifi.content.repository.directory') > -1 or prop.indexOf('nifi.provenance.repository.directory') > -1
      nifi.config.data_dirs ?= []
      nifi.config.data_dirs.push properties[prop] for prop in props
