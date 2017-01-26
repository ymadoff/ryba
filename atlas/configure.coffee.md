
## Configuration
Apache Atlas Metadata Server Configuration. Atlas enables Hadoop users to manage
more efficiently their data.
- Data Classification
- Centralized auditing
- Search & Lineage
- Scurity & Policy Engine

Internally Atlas embeds a [Titan][titan] graph database. Titan for working, needs
a solr cluster for storing indexes and an HBase cluster as the data storage.

Atlas needs also kafka as a bus to broadcats message betwwen the different components
(e.g. Hive, Ranger).


    module.exports = ->
      # Servers onfiguration
      {realm, core_site} = @config.ryba
      atlas_ctxs = @contexts 'ryba/atlas'
      ranger_ctxs = @contexts 'ryba/ranger/tagsync'
      hs2_ctxs = @contexts 'ryba/hive/server2'
      zk_ctxs = @contexts 'ryba/zookeeper/server'
      kafka_ctxs = @contexts 'ryba/kafka/broker'
      hm_ctxs = @contexts 'ryba/hbase/master'
      sc_ctxs = @contexts 'ryba/solr/cloud'
      scd_ctxs = @contexts 'ryba/solr/cloud_docker'
      atlas = @config.ryba.atlas ?= {}
      atlas.conf_dir ?= '/etc/atlas/conf'
      atlas.log_dir ?= '/var/log/atlas'
      atlas.pid_dir ?= '/var/run/atlas'
      atlas.server_opts ?= ''
      atlas.server_heap ?= ''
      # User
      atlas.user = name: atlas.user if typeof atlas.user is 'string'
      atlas.user ?= {}
      atlas.user.name ?= 'atlas'
      atlas.user.system ?= true
      atlas.user.comment ?= 'atlas User'
      atlas.user.home ?= '/var/lib/atlas'
      atlas.user.groups ?= ['hadoop']
      # Group
      atlas.group = name: atlas.group if typeof atlas.group is 'string'
      atlas.group ?= {}
      atlas.group.name ?= 'atlas'
      atlas.group.system ?= true
      atlas.user.gid = atlas.group.name
      atlas.cluster_name ?= 'atlas-on-ryba-cluster'
      # Internal Configuration
      # Configuration
      atlas.application ?= {}
      atlas.application.properties ?= {}

## Configuration
      
      atlas.application.properties['atlas.server.bind.address'] ?= "#{@config.host}"
      atlas.application.properties['atlas.taxonomy.default.name'] ?= 'Catalog'
      atlas.application.properties['atlas.rest-csrf.enabled'] ?= 'true'
      atlas.application.properties['atlas.rest-csrf.browser-useragents-regex'] ?= '^Mozilla.*,^Opera.*,^Chrome.*'
      atlas.application.properties['atlas.rest-csrf.methods-to-ignore'] ?= 'GET,OPTIONS,HEAD,TRACE'
      atlas.application.properties['atlas.rest-csrf.custom-header'] ?= 'X-XSRF-HEADER'
      atlas.application.properties['atlas.feature.taxonomy.enable'] ?= 'true'

## Kerberos
Atlas, when communicating with other components (Solr,HBase,Kafka) needs to authenticate
itself as a client. It uses the JAAS mechanism.
The JAAS informations can be set via a jaas file or the properties can be set directly
from atlas-application.properties file.
      
      atlas.application.properties['atlas.authentication.method'] ?= @config.ryba.security
      atlas.application.properties['atlas.authentication.principal'] ?= "#{atlas.user.name}/_HOST@#{realm}"
      atlas.application.properties['atlas.authentication.keytab'] ?= '/etc/security/keytabs/atlas.service.keytab'
      atlas.application.properties['atlas.http.authentication.enabled'] ?= true
      atlas.application.properties['atlas.http.authentication.type'] ?=  atlas.application.properties['atlas.authentication.method']
      atlas.application.properties['atlas.http.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{realm}"
      atlas.application.properties['atlas.http.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      # atlas.application.properties['atlas.jaas.Client.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
      # atlas.application.properties['atlas.jaas.Client.loginModuleControlFlag'] ?= 'required'
      # atlas.application.properties['atlas.jaas.Client.option.useKeyTab'] ?= 'true'
      # atlas.application.properties['atlas.jaas.Client.option.storeKey'] ?= 'true'
      # atlas.application.properties['atlas.jaas.Client.option.useTicketCache'] ?= 'false'
      # atlas.application.properties['atlas.jaas.Client.option.doNotPrompt'] ?= 'false'
      # atlas.application.properties['atlas.jaas.Client.option.keyTab'] ?= atlas.application.properties['atlas.authentication.keytab']
      # atlas.application.properties['atlas.jaas.Client.option.principal'] ?= atlas.application.properties['atlas.authentication.principal'].replace '_HOST', @config.host

## Kerberos Atlas Admin User
      
      if atlas.application.properties['atlas.authentication.method'] is 'kerberos'
        match_princ = /^(.+?)[@\/]/.exec atlas.application.properties['atlas.authentication.principal']
        throw Error 'Invalid Atlas  principal' unless match_princ?
        atlas.admin_principal ?= "#{atlas.user.name}@#{realm}"
        atlas.admin_password ?= 'atlas123'
        match_admin = /^(.+?)[@\/]/.exec atlas.admin_principal
        throw Error "Principal Name does not match admin user name" unless match_admin[1] is match_princ[1]

## Authentication Method
Several authentication method can be used (Kerberos, ldap, file).
More that one method can be enabled. An admin user should exist for managinf other.

      atlas.application.properties['atlas.authentication.method.ldap'] ?= 'false' #No custom configs
      atlas.application.properties['atlas.authentication.method.kerberos'] ?= "#{@config.ryba.security is 'kerberos'}"
      atlas.application.properties['atlas.authentication.method.file'] ?= 'true'
      # Configure kerberos authentication
      if atlas.application.properties['atlas.authentication.method.kerberos'] is 'true'
        atlas.application.properties['atlas.authentication.method.kerberos.principal'] ?= atlas.application.properties['atlas.http.authentication.kerberos.principal']
        atlas.application.properties['atlas.authentication.method.kerberos.keytab'] ?= atlas.application.properties['atlas.http.authentication.kerberos.keytab']
        atlas.application.properties['atlas.authentication.method.kerberos.name.rules'] ?= core_site['hadoop.security.auth_to_local']
      # Configure file authentication
      if atlas.application.properties['atlas.authentication.method.file'] is 'true'
        atlas.application.properties['atlas.authentication.method.file.filename'] ?= "#{atlas.conf_dir}/users-credentials.properties"
        atlas.admin_user ?= 'admin'
        atlas.admin_password ?= 'admin123'
        atlas.user_creds ?= {}
        atlas.user_creds["#{atlas.admin_user}"] ?= 
          name: "#{atlas.admin_user}"
          password: "#{atlas.admin_password}"
          group: "ADMIN"

## Authorization
Atlas accepts only simple (file) or Ranger based [authorization](http://atlas.incubator.apache.org/Authentication-Authorization.html).
      
      atlas.application.properties['atlas.authorizer.impl'] ?= if ranger_ctxs.length > 0 then 'ranger' else 'simple'
      if atlas.application.properties['atlas.authorizer.impl'] is 'simple'
        atlas.application.properties['atlas.auth.policy.file'] ?= "#{atlas.conf_dir}/policy-store.txt"
        atlas.admin_users ?= []
        atlas.admin_users.push atlas.admin_users if atlas.admin_user? and atlas.admin_users.indexOf(atlas.admin_user) isnt -1
        

## Automatic Check on start up
Atlas server does take care of parallel executions of the setup steps.

      atlas.application.properties['atlas.server.run.setup.on.start'] ?= 'false'

## SSL
Atlas SSL Encryption can be enabled by configuring following properties.

      atlas.serverkey_password ?= 'ryba123'
      atlas.keystore_password ?= 'ryba123'
      atlas.truststore_password ?= 'ryba123'
      atlas.application.properties['atlas.enableTLS'] ?= 'true'
      atlas.application.properties['keystore.file'] ?= "#{atlas.conf_dir}/keystore"
      atlas.application.properties['truststore.file'] ?= "#{atlas.conf_dir}/truststore"
      atlas.application.properties['client.auth.enabled'] ?= "false"
      atlas.application.properties['atlas.server.http.port'] ?= '21000'
      atlas.application.properties['atlas.server.https.port'] ?= '21443'
      # http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/CommandsManual.html#credential
      # for now ryba only support creating the jceks file on the local atlas server.
      # but you can manually (if using the same truststore and keystore on each server)
      # uploading the provider generate into hdfs
      atlas.application.properties['cert.stores.credential.provider.path'] ?= "jceks://file#{atlas.conf_dir}/credential.jceks"
      protocol = if atlas.application.properties['atlas.enableTLS'] is 'true' then 'https' else 'http'
      port = atlas.application.properties["atlas.server.#{protocol}.port"]
      atlas.application.properties['atlas.app.port'] ?= port

## REST Address
      
      rest_address = "#{protocol}://#{@config.host}:#{port}"
      atlas.application.properties['atlas.rest.address'] ?= rest_address
      atlas.application.urls ?= "#{rest_address}"

## High Availability
From 7.0 Atlas Metada server support high availability in an active/passive fashion.
Failover is configured automatically through zookeeper.
The Quorum property is mandatory even if the HA is not enabled or the following error is thrown
Error injecting constructor, java.lang.NullPointerException: connectionString cannot be null

      quorum = for zk_ctx in zk_ctxs
        "#{zk_ctx.config.host}:#{zk_ctx.config.ryba.zookeeper.config['clientPort']}"
      atlas.application.properties['atlas.server.ha.zookeeper.connect'] ?= quorum.join ','
      atlas.ha_enabled = if atlas_ctxs.length > 1 then true else false
      if atlas.ha_enabled

### Zookeeper

A zookeeper quorum is needed for HA. 

        atlas.application.properties['atlas.server.ha.zookeeper.acl'] ?= "sasl:#{atlas.user.name}@#{realm}"
        atlas.application.properties['atlas.server.ha.zookeeper.auth'] ?= "sasl:#{atlas.user.name}@#{realm}"
        atlas.application.properties['atlas.server.ha.zookeeper.zkroot'] ?= '/apache_atlas'

## High Availability with Automatic Failover

Using Official atlas [documentation](http://atlas.incubator.apache.org/HighAvailability.html) 
for HA configuration, (not available on HDP website).
Becareful, even if you can override it, ryba does configure atlas server with the same
port.

      atlas_shortnames = for atlas_ctx in atlas_ctxs then atlas_ctx.config.shortname
      atlas.application.properties['atlas.server.ha.enabled'] ?= if atlas_ctxs.length > 1 then 'true' else 'false'
      atlas.application.properties['atlas.server.ids'] ?= atlas_shortnames.join ','
      for atlas_ctx in atlas_ctxs
        atlas.application.properties["atlas.server.address.#{atlas_ctx.config.shortname}"] ?= "#{atlas_ctx.config.host}:#{port}"

##  Apache Kafka Notification
Required for Ranger integration or anytime there is a consumer of entity change notifications.
    
      [kafka_ctx] = kafka_ctxs
      if kafka_ctx?
        # Includes the required Atlas directories to the hadoop-env configuration export
        @config.ryba.hadoop_classpath = add_prop  @config.ryba.hadoop_classpath, "#{atlas.conf_dir}:/usr/hdp/current/atlas-server/hook/hive", ':'
        # Configure Kafka Broker properties
        atlas.application.properties['atlas.notification.embedded'] ?= 'false'
        atlas.application.properties['atlas.kafka.sasl.kerberos.service.name'] ?= 'kafka'
        atlas.application.properties['atlas.kafka.data'] ?= "#{atlas.user.home}/data/kafka" # {atlas.user.home}/keystore"
        atlas.application.properties['atlas.kafka.zookeeper.connect'] ?= "#{kafka_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect']}"
        atlas.application.properties['atlas.kafka.zookeeper.session.timeout.ms'] ?= '1000'
        atlas.application.properties['atlas.kafka.zookeeper.sync.time.ms'] ?= '20'
        atlas.application.properties['atlas.kafka.auto.commit.interval.ms'] ?= '1000'
        atlas.application.properties['atlas.kafka.hook.group.id'] ?= 'atlas'
        atlas.application.properties['atlas.kafka.entities.group.id'] ?= 'atlas'
        atlas.application.properties['atlas.kafka.auto.commit.enable'] ?= 'false'
        atlas.application.properties['atlas.notification.create.topics'] ?= 'false'
        atlas.application.properties['atlas.notification.replicas'] ?= "#{kafka_ctxs.length}"
        atlas.application.properties['atlas.notification.log.failed.messages'] ?= '500'
        atlas.application.properties['atlas.notification.consumer.retry.interval'] ?= '10'
        atlas.application.properties['atlas.notification.hook.retry.interval'] ?= '1000'
        atlas.application.properties['atlas.kafka.auto.offset.reset'] ?= 'smallest'
        atlas.application.properties['atlas.notification.topics'] ?= 'ATLAS_HOOK,ATLAS_ENTITIES'
        #kafka Jaas client configuration
        atlas.application.properties['atlas.jaas.KafkaClient.loginModuleControlFlag'] ?= 'required'
        atlas.application.properties['atlas.jaas.KafkaClient.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
        atlas.application.properties['atlas.jaas.KafkaClient.option.keyTab'] ?= '/etc/security/keytabs/atlas.service.keytab'
        atlas.application.properties['atlas.jaas.KafkaClient.option.principal'] ?= "#{atlas.user.name}/_HOST@#{realm}"
        atlas.application.properties['atlas.jaas.KafkaClient.option.serviceName'] ?= 'kafka'
        atlas.application.properties['atlas.jaas.KafkaClient.option.storeKey'] ?= 'true'
        atlas.application.properties['atlas.jaas.KafkaClient.option.useKeyTab'] ?= 'true'
        # Choose kafka broker channel by preference order
        chanels = []
        chanels.push 'SASL_SSL' if @config.ryba.security is 'kerberos' and atlas.application.properties['atlas.enableTLS'] is 'true'
        chanels.push 'SASL_PLAINTEXT' if @config.ryba.security is 'kerberos'
        chanels.push 'SSL' if atlas.application.properties['atlas.enableTLS'] is 'true'
        chanels.push 'PLAINTEXT'
        #recording chosen protocol
        atlas.application.properties['atlas.kafka.security.protocol'] ?= chanels[0]
        atlas.application.kafka_chanel = atlas.application.properties['atlas.kafka.security.protocol']
        # `kafka.broker.protocols` are available client protocols for communicating with broker
        if atlas.application.kafka_chanel in kafka_ctxs[0].config.ryba.kafka.broker.protocols 
          brokers = kafka_ctxs.map( (ctx) => 
            "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports[atlas.application.kafka_chanel]}"
          ).join ','
          # construcut the bootstrap listeners string base on channel
          # i.e.: SASL_SSL://master1.ryba:9096,master2.ryba:9096,master3.ryba:9096 for example
          atlas.application.properties['atlas.kafka.bootstrap.servers'] ?= "#{atlas.application.kafka_chanel}://#{brokers}"
          if atlas.application.kafka_chanel in ['SSL','SASL_SSL']
            atlas.application.properties['atlas.kafka.ssl.truststore.location'] ?= @config.ryba.kafka.consumer.config['']
            atlas.application.properties['atlas.kafka.ssl.truststore.password'] ?= @config.ryba.kafka.consumer.config['ssl.truststore.password']
        else
          throw Error "Atlas Selected Kafka Protocol #{atlas.application.kafka_chanel} is not allowed by Kafka Brokers configuration"

## Apache Hive hook configuration
Mechanism: The Apache Hive Hook (or Atlas hook) is running directly inside the
hiveserver2's JVM. As a consequence, Kafka Client configuration must be configured 
on the hiveserver2 side.
Ryba does the follwing steps:
- Configure Hiveserver2' hive-site.xml file with Atlas Props

Write Atlas Configuration file for hive's bridge. Atlas.Hive.Hook needs the atlas applcation
file in the hive-server2's configuration directory. 
Note: The file needs to be called atlas-application.properties as the name is
hard coded.

      atlas.hive_bridge_enabled ?= hs2_ctxs.length > 0
      if atlas.hive_bridge_enabled
        # Configure Hive site properties
        for hive_ctx in hs2_ctxs
          server2 = hive_ctx.config.ryba.hive.server2
          server2.atlas ?= {}
          server2.atlas.client ?= {}
          server2.atlas.client.properties ?= {}
          server2.atlas.client.properties['atlas.http.authentication.enabled'] ?= atlas.application.properties['atlas.http.authentication.enabled']
          server2.atlas.client.properties['atlas.http.authentication.type'] ?= atlas.application.properties['atlas.http.authentication.type']
          server2.atlas.application ?= {}
          server2.atlas.application.properties ?= {}
          server2.atlas.application.properties['atlas.hook.hive.synchronous'] ?= 'false'
          server2.atlas.application.properties['atlas.hook.hive.numRetries'] ?= '3'
          server2.atlas.application.properties['atlas.hook.hive.minThreads'] ?= '5'
          server2.atlas.application.properties['atlas.hook.hive.maxThreads'] ?= '5'
          server2.atlas.application.properties['atlas.hook.hive.keepAliveTime'] ?= '10'
          server2.atlas.application.properties['atlas.hook.hive.queueSize'] ?= '10000'
          server2.site['atlas.cluster.name'] ?= "#{atlas.cluster_name}"
          # Step 1 - check if the rest adress already written
          # Step 2 (only if 1) Check if an url is already written
          server2.site['atlas.rest.address'] = add_prop server2.site['atlas.rest.address'], rest_address, ','
          server2.site['hive.exec.post.hooks'] = add_prop server2.site['hive.exec.post.hooks'], 'org.apache.atlas.hive.hook.HiveHook', ','
          server2.aux_jars = add_prop server2.aux_jars, "/usr/hdp/current/atlas-client/hook/hive", ':'
          
### Apache Hive Hook Kafka Notification
          
          chanels = []
          chanels.push 'SASL_SSL' if @config.ryba.security is 'kerberos' and server2.site['hive.server2.use.SSL'] is 'true'
          chanels.push 'SASL_PLAINTEXT' if @config.ryba.security is 'kerberos'
          chanels.push 'SSL' if server2.site['hive.server2.use.SSL'] is 'true'
          chanels.push 'PLAINTEXT'
          server2.atlas.application.properties['atlas.kafka.security.protocol'] ?= chanels[0]
          server2.atlas.application.properties['atlas.notification.topics'] ?= atlas.application.properties['atlas.notification.topics']
          server2.atlas.application.properties['atlas.kafka.bootstrap.servers'] ?= atlas.application.properties[prop]
          # Configure Hive Server2 JAAS Properties for posting notifications to Kafka
          if server2.atlas.application.properties['atlas.kafka.security.protocol'] in ['SASL_PLAINTEXT','SASL_SSL']
            server2.atlas.application.properties['atlas.jaas.KafkaClient.loginModuleControlFlag'] ?= 'required'
            server2.atlas.application.properties['atlas.jaas.KafkaClient.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
            server2.atlas.application.properties['atlas.jaas.KafkaClient.option.keyTab'] ?= server2.site['hive.server2.authentication.kerberos.keytab']
            server2.atlas.application.properties['atlas.jaas.KafkaClient.option.principal'] ?= server2.site['hive.server2.authentication.kerberos.principal']
            server2.atlas.application.properties['atlas.jaas.KafkaClient.option.serviceName'] ?= 'kafka'
            server2.atlas.application.properties['atlas.jaas.KafkaClient.option.storeKey'] ?= 'true'
            server2.atlas.application.properties['atlas.jaas.KafkaClient.option.useKeyTab'] ?= 'true'
          if server2.atlas.application.properties['atlas.kafka.security.protocol'] in ['SSL','SASL_SSL']
            server2.atlas.application.properties['atlas.kafka.ssl.truststore.location'] ?= hive_ctx.config.ryba.ssl_client['ssl.client.truststore.location']
            server2.atlas.application.properties['atlas.kafka.ssl.truststore.password'] ?= hive_ctx.config.ryba.ssl_client['ssl.client.truststore.password']
          #Administators can choose a different protocol for Atlas Kafka Notification
          protocol = server2.atlas.application.properties['atlas.kafka.security.protocol']
          if protocol in kafka_ctxs[0].config.ryba.kafka.broker.protocols
            brokers = kafka_ctxs.map( (ctx) => 
              "#{ctx.config.host}:#{ctx.config.ryba.kafka.broker.ports[protocol]}"
            ).join ','
            # construcut the bootstrap listeners string base on channel
            # i.e.: SASL_SSL://master1.ryba:9096,master2.ryba:9096,master3.ryba:9096 for example
            server2.atlas.application.properties['atlas.kafka.bootstrap.servers'] ?= "#{protocol}://#{brokers}"
          else
            throw Error "Atlas Hive Bridge Hook Selected Protocol #{atlas.application.kafka_chanel} is not allowed by Kafka Brokers configuration"

### Atlas Hive Properties action

        if @contexts('ryba/atlas')[0].config.host is @config.host#Only bind once
          hive_ctx
          .before
            type: ['service','start']
            name: 'hive-server2'
            handler: -> 
              @registry.register 'hdp_select', 'ryba/lib/hdp_select'
              @service 'atlas-metadata*hive-plugin*'
              @hdp_select 'atlas-client' #needed by hive server2 aux jars
          .after
            type: ['hconfigure']
            target: "#{hive_ctx.config.ryba.hive.server2.conf_dir}/hive-site.xml"
            handler: ->
              @file.properties
                header: 'Atlas Hiveserver2 Client Properties'
                target: '/etc/hive/conf/client.properties'
                content: server2.atlas.client.properties
              @file.properties
                header: 'Atlas Client Properties'
                target: "#{hive_ctx.config.ryba.hive.server2.conf_dir}/client.properties"
                content: server2.atlas.client.properties
              @file.properties
                header: 'Atlas Hiveserver2 Application Properties'
                target: "#{hive_ctx.config.ryba.hive.server2.conf_dir}/atlas-application.properties"
                content: server2.atlas.application.properties

## Ranger Tag Base Policies configuration

        for ctx in ranger_ctxs
          ctx.config.ryba.ranger ?= {}
          ctx.config.ryba.ranger.tagsync ?= {}
          ctx.config.ryba.ranger.tagsync.atlas_properties ?= {}
          for prop in [
            'atlas.notification.embedded'
            'atlas.kafka.data'
            'atlas.kafka.zookeeper.connect'
            'atlas.kafka.bootstrap.servers'
            'atlas.kafka.security.protocol'
            'atlas.kafka.zookeeper.session.timeout.ms'
            'atlas.kafka.zookeeper.sync.time.ms'
            'atlas.kafka.auto.commit.interval.ms'
            'atlas.kafka.hook.group.id'
          ] then do 
            ctx.config.ryba.ranger.tagsync.atlas_properties[prop] ?= atlas.application.properties[prop]

## Atlas Metada Server Environment

      atlas.env ?= {}
      atlas.metadata_opts ?= {}
      # atlas.metadata_opts['java.security.auth.login.config'] ?= "#{atlas.conf_dir}/atlas-server.jaas"
      atlas.atlas_opts ?= {}
      atlas.atlas_opts['java.security.auth.login.config'] ?= "#{atlas.conf_dir}/atlas-server.jaas"
      atlas.atlas_opts['log4j.configuration'] ?= 'atlas-log4j.xml'
      atlas.env['ATLAS_PID_DIR'] ?= "#{atlas.pid_dir}"
      atlas.env['ATLAS_LOG_DIR'] ?= "#{atlas.log_dir}"
      atlas.env['ATLAS_HOME_DIR'] ?= '/usr/hdp/current/atlas-server'
      atlas.env['ATLAS_DATA_DIR'] ?= "#{atlas.user.home}/data"
      atlas.env['ATLAS_EXPANDED_WEBAPP_DIR'] ?= "#{atlas.user.home}/server/webapp"
      atlas.env['HBASE_CONF_DIR'] ?= "#{atlas.conf_dir}/hbase"
      
## Atlas Server Heap
      
      atlas.min_heap ?= '512m'
      atlas.max_heap ?= '512m'

## Atlas Ranger User

      atlas.ranger_user ?=
        "name": 'atlas'
        "firstName": 'atlas'
        "lastName": 'hadoop'
        "emailAddress": 'atlas@hadoop.ryba'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1

## Titan MetaData Database
Atlas uses Titan as its its metadata storage.
The Titan database can be configured with HBase as its storage database, and
Solr for its indexing backend

### Storage Backend

      atlas.storage_engine ?= 'hbase'
      if atlas.storage_engine is 'hbase'
        if hm_ctxs.length > 0
          atlas.application.properties['atlas.graph.storage.backend'] ?= 'hbase'
          atlas.application.properties['atlas.graph.storage.hostname'] ?= hm_ctxs[0].config.ryba.hbase.master.site['hbase.zookeeper.quorum']
          atlas.application.properties['zookeeper.znode.parent'] ?= hm_ctxs[0].config.ryba.hbase.master.site['zookeeper.znode.parent']
          atlas.application.namespace ?= 'atlas'
          atlas.application.properties['atlas.graph.storage.hbase.table'] ?= "#{atlas.application.namespace}:atlas_titan"
          atlas.application.properties['atlas.audit.hbase.tablename'] ?= "#{atlas.application.namespace}:atlas_entity_audit"
        else
          throw Error 'No HBase cluster is configured'

### Indexing Engine
Atlas support only solr on cloud mode. Atlas' Ryba installation support solrcoud 
in or out of docker.
      
      atlas.indexing_engine ?= 'solr'
      if atlas.indexing_engine is 'solr'
        atlas.solr_type ?= 'cloud_docker'
        solr_ctx = {}
        atlas.application.properties['atlas.solr.kerberos.enable'] ?= "#{@config.ryba.security is 'kerberos'}"
        switch atlas.solr_type
          when 'cloud'
            throw Error 'No Solr Cloud Server configured' unless sc_ctxs.length > 0
            atlas.solr_admin_user ?= 'solr'
            atlas.solr_admin_password ?= 'SolrRocks' #Default
            atlas.cluster_config ?=
              atlas_collection_dir: "#{sc_ctxs[0].config.ryba.solr.cloud.conf_dir}/clusters/atlas_solr"
              hosts: sc_ctxs.map( (ctx)-> ctx.config.host)
            # register collection creation just once
            if @contexts('ryba/atlas').map( (ctx) -> ctx.config.host )[0] is @config.host
              sc_ctxs[0]
              .after
                type: ['service','start']
                name: 'solr'
                handler: -> @call 'ryba/atlas/solr_layout'
          when 'cloud_docker'
            throw Error 'No Solr Cloud Server configured' unless scd_ctxs.length > 0
            cluster_name = atlas.solr_cluster_name ?= 'atlas_cluster'
            atlas.solr_admin_user ?= 'solr'
            atlas.solr_admin_password ?= 'SolrRocks' #Default
            atlas.solr_users ?= [
              name: 'ranger'
              secret: 'ranger123'
            ]
            {solr} = @config.ryba
            solr.cloud_docker ?= {}
            solr.cloud_docker.clusters ?= {}
            #Search for a cloud_docker cluster find in solr.cloud_docker.clusters
            if not solr.cloud_docker.clusters[cluster_name]?
              cluster_config = {}
              for solr_ctx in scd_ctxs
                solr = solr_ctx.config.ryba.solr ?= {}
                #By default Ryba search for a solr cloud cluster named ryba_ranger_cluster in config
                # Configures one cluster if not in config
                solr.cloud_docker.clusters ?= {}
                cluster_config  = solr.cloud_docker.clusters[cluster_name] ?= {}
                cluster_config.volumes ?= []
                cluster_config.atlas_collection_dir = "#{solr.cloud_docker.conf_dir}/clusters/#{cluster_name}/atlas_solr"
                cluster_config.volumes.push "#{cluster_config.atlas_collection_dir}:/atlas_solr" if cluster_config.volumes.indexOf("#{solr.cloud_docker.conf_dir}/clusters/#{cluster_name}/atlas_solr:/atlas_solr") is -1
                cluster_config['containers'] ?= scd_ctxs.length
                cluster_config['master'] ?= scd_ctxs[0].config.host
                cluster_config['heap_size'] ?= '256m'
                cluster_config['port'] ?= 8985
                cluster_config.zk_opts ?= {}
                cluster_config['hosts'] ?= scd_ctxs.map (ctx) -> ctx.config.host 
                configure_solr_cluster solr_ctx , cluster_name, cluster_config
              atlas.cluster_config = scd_ctxs[0].config.ryba.solr.cloud_docker.clusters[cluster_name]
              scd_ctxs[0]
              .after
                type: ['docker','compose','up']
                target: "#{solr.cloud_docker.conf_dir}/clusters/#{cluster_name}/docker-compose.yml"
                handler: -> @call 'ryba/atlas/solr_layout'
            else
              atlas.cluster_config = solr.cloud_docker.clusters[cluster_name]
            urls = cluster_config.zk_connect.split(',').map( (host) -> "#{host}/#{cluster_config.zk_node}").join(',')
            atlas.application.properties['atlas.graph.index.search.solr.zookeeper-url'] ?= "#{urls}"
            atlas.application.properties['atlas.graph.index.search.solr.mode'] ?= 'cloud'
            atlas.application.properties['atlas.graph.index.search.backend'] ?= 'solr5'

    add_prop = (value, add, separator) ->
      throw Error 'No separator provided' unless separator?
      value ?= ''
      return add if value.length is 0
      return if value.indexOf(add) is -1 then "#{value}#{separator}#{add}" else value

## Dependencies
  
    configure_solr_cluster = require '../solr/cloud_docker/clusterize'
    {merge} = 'mecano/lib/misc'

[titan]:(http://titan.thinkaurelius.com)
