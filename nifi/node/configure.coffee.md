
## Configure

    module.exports = handler: ->
      nifi = @config.ryba.nifi ?= {}
      {realm} = @config.ryba
      nifi.version ?= '0.6.0'
      nifi.root_dir ?= '/usr'
      nifi.install_dir ?= "#{nifi.root_dir}/nifi/#{nifi.version}"
      nifi.latest_dir ?= "#{nifi.root_dir}/nifi/current"
      nifi.source ?= "https://archive.apache.org/dist/nifi/#{nifi.version}/nifi-#{nifi.version}-bin.tar.gz"
      nifi.node  ?= {}
      nifi.node.latest_dir ?= "#{nifi.root_dir}/nifi/current/nifi-node"
      nifi.node.install_dir ?= "#{nifi.install_dir}/nifi-node"
      nifi.node.conf_dir ?= '/etc/nifi-node/conf'
      nifi.node.log_dir ?= '/var/log/nifi'

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
      nifi.user.limits.nproc ?= true
      nifi.user.gid = nifi.group.name 
      config = nifi.node.config ?= {}
      properties = config.properties ?= {}
      [ncm_ctx] = @contexts 'ryba/nifi/manager', require('../manager/configure').handler
      throw Error 'No NiFi Manager configured' unless ncm_ctx?
      {manager} = ncm_ctx.config.ryba.nifi
      #version
      properties['nifi.version'] ?= "#{nifi.version}"

## Security
      
      properties['nifi.web.http.host'] ?= "#{@config.host}"
      properties['nifi.web.http.port'] ?= '9850'
      properties['nifi.web.https.host'] ?= "#{@config.host}"
      properties['nifi.web.https.port'] ?= '9860'
      properties['nifi.cluster.protocol.is.secure'] ?= manager.config.properties['nifi.cluster.protocol.is.secure']
      if properties['nifi.cluster.protocol.is.secure'] is 'true'
        properties['nifi.web.http.port'] = ''          
        properties['nifi.web.http.host'] = ''          
        properties['nifi.security.keystore'] ?= "#{nifi.node.conf_dir}/keystore"
        properties['nifi.security.keystoreType'] ?= 'JKS'
        properties['nifi.security.keystorePasswd'] ?= 'nifi123'
        properties['nifi.security.keyPasswd'] ?= 'nifi123'
        properties['nifi.security.truststore'] ?= "#{nifi.node.conf_dir}/truststore"
        properties['nifi.security.truststoreType'] ?= 'JKS'
        properties['nifi.security.truststorePasswd'] ?= 'nifi123'
        for property in  [
          'nifi.security.needClientAuth'
          'nifi.kerberos.krb5.file'
          # Valid Authorities include: ROLE_MONITOR,ROLE_DFM,ROLE_ADMIN,ROLE_PROVENANCE,ROLE_NIFI
          # role given to anonymous users
          'nifi.security.anonymous.authorities'
        ] then properties[property] ?= manager.config.properties[property]

## Cluster Configuration  

Different type of properties has to be set:
- How NiFi Master(manager) and Slaves(nodes) communicates (port binding).
- Where Authentication take places for master/slaves (and ACLs)
- Where to store states of the cluster

      # required property to define the server as a master role
      properties['nifi.cluster.is.node'] ?= 'true'
      # Defines the port where manager will be accessible to communicate with nodes
      properties['nifi.cluster.node.address'] ?= "#{@config.host}"
      properties['nifi.cluster.node.protocol.port'] ?= '9870'
      properties['nifi.cluster.node.unicast.manager.address'] ?= "#{ncm_ctx.config.host}"
      properties['nifi.cluster.node.unicast.manager.protocol.port'] ?= "#{manager.config.properties['nifi.cluster.manager.protocol.port']}"
      # ACLS
      # In a secured cluster, the authentication takes place on the niFi master server.
      # The authority-providers files has to provisionned for both `cluster-ncm-provider` (for the manager)
      # and `cluster-node-provider` for each nodes.
      properties['nifi.security.user.authority.provider'] ?= 'cluster-node-provider'
      properties['nifi.authority.provider.configuration.file'] ?= "#{nifi.node.conf_dir}/authority-providers.xml" # External file describing conf
      # A port must be defined for the authentication part
      config.authority_providers ?= {}
      config.authority_providers.ncm_port ?= manager.config.authority_providers.ncm_port
      config.authority_providers.node_port ?= manager.config.authority_providers.ncm_port
      
      # State provider
      # Defines how and where niFi servers stores states about nodes.
      properties['nifi.state.management.provider.local'] ?= 'local-provider' # present by default
      properties['nifi.state.management.configuration.file'] ?= "#{nifi.node.conf_dir}/state-management.xml" # External file describing conf
      # NiFi support only zookeeper as cluster wide state provider
      # NiFi can use an embbed zookeeper nifi.state.management.embedded.zookeeper.start is set to true
      # We support only external zookeeper quorum
      properties['nifi.state.management.provider.cluster'] ?= manager.config.properties['nifi.state.management.provider.cluster']
      switch properties['nifi.state.management.provider.cluster']
        when 'zk-provider'
          nifi.zk_connect ?= ncm_ctx.config.ryba.nifi.zk_connect
          nifi.zk_node ?= ncm_ctx.config.ryba.nifi.zk_node
          if @config.ryba.security is 'kerberos'
            nifi.node.krb5_principal ?=  "#{nifi.user.name}_node/#{@config.host}@#{realm}"
            nifi.node.krb5_keytab ?=  '/etc/security/keytabs/nifi.node.service.keytab'
        else
          throw Error 'No other cluster state provider is supported for now'
      #Login Provider
      properties['nifi.login.identity.provider.configuration.file'] ?= "#{nifi.node.conf_dir}/login-identity-providers.xml"

      # secure inner connection and remote
      properties['nifi.remote.input.secure'] ?= 'true'
      properties['nifi.remote.input.socket.port'] ?= '9890'
      properties['nifi.remote.input.socket.host'] ?= "#{@config.host}"
      
# Core Properties #

      properties['nifi.flow.configuration.file'] ?= "#{nifi.user.home}/flow.xml.gz"
      properties['nifi.flow.configuration.archive.dir'] ?= "#{nifi.user.home}/archive/"
      properties['nifi.flowfile.repository.directory'] ?= "#{nifi.user.home}/flowfile_repository"
      
      properties['nifi.templates.directory'] ?= "#{nifi.user.home}/templates"
      properties['nifi.nar.library.directory'] ?= "#{nifi.node.latest_dir}/lib"
      properties['nifi.nar.working.directory'] ?= "#{nifi.user.home}/work/nar/"
      properties['nifi.documentation.working.directory'] ?= "#{nifi.user.home}/work/docs/components"
      
      # H2 Settings
      properties['nifi.database.directory'] ?= "#{nifi.user.home}/database_repository"
      
      # Content Repository
      properties['nifi.content.repository.directory.default'] ?= "#{nifi.user.home}/content_repository"
      
      # Persistent Provenance Repository Properties
      properties['nifi.provenance.repository.directory.default'] ?= "#{nifi.user.home}/provenance_repository"
      
      # web properties #
      properties['nifi.web.war.directory'] ?= "#{nifi.node.latest_dir}/lib"
      properties['nifi.web.jetty.working.directory'] ?= "#{nifi.user.home}/work/jetty"
      

## JAVA Opts

      nifi.java ?= {}
      nifi.java.opts ?= {}
      nifi.java.opts['permsize'] ?= '128M'
      nifi.java.opts['maxpermsize'] ?= '256M'
