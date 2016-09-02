
## Configure
This modules configures every hadoop plugin needed to enable Ranger. It configures
variables but also inject some function to be executed.

    module.exports = handler: ->
      require('../../hadoop/core/configure').handler.call @
      require('../../commons/db_admin').handler.call @
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn', require('../../hadoop/hdfs_nn/configure').handler
      dn_ctxs = @contexts 'ryba/hadoop/hdfs_dn', require('../../hadoop/hdfs_dn/configure').handler
      nm_ctxs = @contexts 'ryba/hadoop/yarn_nm', require('../../hadoop/yarn_nm/configure').handler
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm', require('../../hadoop/yarn_rm/configure').handler
      hm_ctxs = @contexts 'ryba/hbase/master',  require('../../hbase/master/configure').handler
      rs_ctxs = @contexts 'ryba/hbase/regionserver', require('../../hbase/regionserver/configure').handler
      hbcli_ctxs = @contexts 'ryba/hbase/client', require('../../hbase/client/configure').handler
      kb_ctxs = @contexts 'ryba/kafka/broker', require('../../kafka/broker/configure').handler
      sc_ctxs = @contexts 'ryba/solr/cloud', require('../../solr/cloud/configure').handler
      st_ctxs = @contexts 'ryba/solr/standalone', require('../../solr/standalone/configure').handler
      scd_ctxs = @contexts 'ryba/solr/cloud_docker', require('../../solr/cloud_docker/configure').handler
      hive_ctxs = @contexts 'ryba/hive/server2', require('../../hive/server2/configure').handler
      {ryba} = @config
      {realm, db_admin, ssl, core_site, hdfs, hadoop_group} = ryba
      ranger = @config.ryba.ranger ?= {}

# Ranger user & group

      # Group
      ranger.group = name: ranger.group if typeof ranger.group is 'string'
      ranger.group ?= {}
      ranger.group.name ?= 'ranger'
      ranger.group.system ?= true
      # User
      ranger.user ?= {}
      ranger.user = name: ranger.user if typeof ranger.user is 'string'
      ranger.user.name ?= ranger.group.name
      ranger.user.system ?= true
      ranger.user.comment ?= 'Ranger User'
      ranger.user.home ?= "/var/lib/#{ranger.user.name}"
      ranger.user.gid ?= ranger.group.name

## Log4j

      ranger.admin.log4j ?= {}
      ranger.admin.log4j['log4j.logger.xaaudit.org.apache.ranger.audit.provider.Log4jAuditProvider'] = 'INFO, hdfsAppender'
      ranger.admin.log4j['log4j.appender.hdfsAppender'] = 'org.apache.log4j.HdfsRollingFileAppender'
      ranger.admin.log4j['log4j.appender.hdfsAppender.hdfsDestinationDirectory'] = 'hdfs://%hostname%:8020/logs/application/%file-open-time:yyyyMMdd%'
      ranger.admin.log4j['log4j.appender.hdfsAppender.hdfsDestinationFile'] = '%hostname%-audit.log'
      ranger.admin.log4j['log4j.appender.hdfsAppender.hdfsDestinationRolloverIntervalSeconds'] = '86400'
      ranger.admin.log4j['log4j.appender.hdfsAppender.localFileBufferDirectory'] = '/tmp/logs/application/%hostname%'
      ranger.admin.log4j['log4j.appender.hdfsAppender.localFileBufferFile'] = '%file-open-time:yyyyMMdd-HHmm.ss%.log'
      ranger.admin.log4j['log4j.appender.hdfsAppender.localFileBufferRolloverIntervalSeconds'] = '15'
      ranger.admin.log4j['log4j.appender.hdfsAppender.localFileBufferArchiveDirectory'] = '/tmp/logs/archive/application/%hostname%'
      ranger.admin.log4j['log4j.appender.hdfsAppender.localFileBufferArchiveFileCount'] = '12'
      ranger.admin.log4j['log4j.appender.hdfsAppender.layout'] = 'org.apache.log4j.PatternLayout'
      ranger.admin.log4j['log4j.appender.hdfsAppender.layout.ConversionPattern'] = '%d{yy/MM/dd HH:mm:ss} [%t]: %p %c{2}: %m%n'
      ranger.admin.log4j['log4j.appender.hdfsAppender.encoding'] = 'UTF-8'

# Ranger xusers
Ranger eanble to create users with its REST API. Required user can be specified in the
ranger config and ryba will create them.
User can be External and Internal. Only Internal users can be created from the ranger webui.

      # Ranger Manager Users
      # Dictionnary containing as a key the name of the ranger admin webui users
      # and value and user properties.
      ranger.users ?= {}
      ranger.users['ryba'] ?=
        "name": 'ryba'
        "firstName": 'ryba'
        "lastName": 'hadoop'
        "emailAddress": 'ryba@hadoop.ryba'
        "password": 'ryba123'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1
      ranger.lock = "/etc/ranger/#{Date.now()}"
      # Ranger Admin configuration
      ranger.admin ?= {}
      ranger.admin.current_password ?= 'admin'
      ranger.admin.password ?= 'rangerAdmin123'
      pass = ranger.admin.password
      if not (/^.*[a-zA-Z]/.test(pass) and /^.*[0-9]/.test(pass)  and pass.length > 8)
       throw Error "new passord's length must be > 8, must contain one alpha and numerical character at lest" 
      ranger.admin.site ?= {}
      ranger.admin.site ?= {}
      ranger.admin.site['ranger.service.http.port'] ?= '6080'
      ranger.admin.site['ranger.service.https.port'] ?= '6182'
      ranger.admin.install ?= {}
      ranger.admin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

# Audit Storage
Ranger can store  audit to different storage type.
- HDFS ( Long term and scalable storage)
- SOLR ( short term storage & Ranger WEBUi)
- DB Flavor ( mid term storage & Ranger WEBUi)
We do not advice to use DB Storage as it is not efficient to query when it grows up.
Hortonworks recommandations are to enable SOLR and HDFS Storage.

      ranger.admin.install['audit_store'] ?= 'solr'

## Solr Audit Database Configuration
Here SOLR configuration is discovered and ranger admin is set.
Ryba support both Solr Cloud mode and Solr Standalone installation. 
The `ranger.admin.solr_type` designated the type of solr used for Ranger.
The type requires differents instruction for configuring Plugins audit.
There are three types available:
- Solr Standalone
- Solr Cloud
- Solr Cloud on docker
When SolrCloud on docker is configured (`ranger.admin.solr_type` to `cloud_docker`),
Ryba configures Ranger by using one of the cluster available
in `config.ryba.solr.cloud_docker.clusters` properties, base on the instance name
set in the following variable `ranger.admin.cluster_name`
  
Note July 2016:
The previous properties works only with (HDP 2.4) `solr.BasicAuthPlugin` (in solr cluster config).
And it is configured by Ryba only in ryba/solr/cloud_docker installation.

      ranger.admin.solr_type ?= 'single'
      solr = {}
      solrs_urls = ''
      solr_ctx = {}
      switch ranger.admin.solr_type
        when 'single'
          throw Error 'No Solr Standalone Server configure' unless st_ctxs.length > 0
          solr_ctx = st_ctxs[0]
          solr = solr_ctx.config.ryba.solr
          ranger.admin.install['audit_solr_port'] ?= ctx.config.ryba.solr.single.port
          solrs_urls = st_ctxs.map( (ctx) -> 
           "#{if solr.single.ssl.enabled  then 'https://'  else 'http://'}#{ctx.config.host}:#{ctx.config.ryba.solr.single.port}")
            .map( (url) -> if ranger.admin.solr_type is 'single' then "#{url}/solr/ranger_audits" else "#{url}")
            .join(',')
          solr_ctx
          .after
            type: 'java_keystore_add'
            keystore: solr["#{ranger.admin.solr_type}"]['ssl_trustore_path']
            storepass: solr["#{ranger.admin.solr_type}"]['ssl_keystore_pwd']
            caname: "hadoop_root_ca"
            handler: -> @call 'ryba/ranger/admin/solr_bootstrap'
        when 'cloud'
          throw Error 'No Solr Cloud Server configure' unless sc_ctxs.length > 0
          solr_ctx = sc_ctxs[0]
          solr = sc_ctxs[0].config.ryba.solr
          ranger.admin.install['audit_solr_port'] ?= ctx.config.ryba.solr.cloud.port
          solrs_urls = sc_ctxs.map( (ctx) -> 
           "#{if solr.cloud.ssl.enabled  then 'https://'  else 'http://'}#{ctx.config.host}:#{ctx.config.ryba.solr.cloud.port}")
            .map( (url) -> if ranger.admin.solr_type is 'single' then "#{url}/solr/ranger_audits" else "#{url}")
            .join(',')
          solr_ctx
          .after
            type: 'java_keystore_add'
            keystore: solr["#{ranger.admin.solr_type}"]['ssl_trustore_path']
            storepass: solr["#{ranger.admin.solr_type}"]['ssl_keystore_pwd']
            caname: "hadoop_root_ca"
            handler: -> @call 'ryba/ranger/admin/solr_bootstrap'
        when 'cloud_docker'
          throw Error 'No Solr Cloud Server configure' unless scd_ctxs.length > 0 or ranger.admin.cluster_name ?
          solr_ctx = scd_ctxs[0]
          solr = if scd_ctxs[0]? then scd_ctxs[0].config.ryba.solr else @config.ryba.solr
          cluster_name = ranger.admin.cluster_name ?= 'ryba_ranger_cluster'
          cluster_config = ranger.admin.cluster_config = solr.cloud_docker.clusters[cluster_name] ?= {}
          cluster_config.ranger ?= {}
          ranger.admin.install['audit_solr_port'] ?= cluster_config.port
          #Search for a cloud_docker cluster find in solr.cloud_docker.clusters
          solrs_urls = cluster_config.hosts.map( (host) ->
           "#{if solr.cloud_docker.ssl.enabled  then 'https://'  else 'http://'}#{host}:#{cluster_config.port}/solr/ranger_audits").join(',')
          if (@contexts 'ryba/ranger/admin').map( (ctx) -> ctx.config.host)[0] is @config.host
            @after
              type: 'service_start'
              name: 'ranger-admin'
              handler: -> 'ryba/ranger/admin/solr_bootstrap'

## Solr Audit Database Bootstrap
Create the `ranger_audits`  collection('cloud')/core('standalone').

      if ranger.admin.install['audit_store'] is 'solr'
        ranger.admin.install['audit_solr_urls'] ?= solrs_urls
        ranger.admin.install['audit_solr_user'] ?= 'ranger'
        ranger.admin.install['audit_solr_password'] ?= 'ranger123'

When Basic authentication is used, the following property can be set to add 
users to solr `ranger.admin.cluster_config.ranger.solr_users`:
  -  An object describing all the users used by the different plugins which will
  write audit to solr.
  - By default if no user are provided, Ryba configure only one user named ranger
  to audit to solr.
Example:
```cson
  ranger.admin.cluster_config.ranger.solr_users =
    name: 'my_plugin_user'
    secret: 'my_plugin_password'

        ranger.admin.cluster_config.ranger.solr_users ?= []
        if ranger.admin.cluster_config.ranger.solr_users.length is 0
          ranger.admin.cluster_confif.ranger.solr_users.push {
            name: "#{ranger.admin.install['audit_solr_user']}"
            secret:"#{ranger.admin.install['audit_solr_password']}"
          }
        ranger.admin.install['audit_solr_zookeepers'] ?= if ranger.admin.solr_type is 'single' then 'NONE' else solr["#{ranger.admin.solr_type}"]['zkhosts']

## Ranger Admin SSL
Configure SSL for Ranger policymanager (webui).

      ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] ?= 'true'
      ranger.admin.site['ranger.service.https.attrib.clientAuth'] ?= 'false'
      ranger.admin.site['ranger.https.attrib.keystore.file'] ?= '/etc/ranger/admin/conf/keystore'
      ranger.admin.site['ranger.service.https.attrib.keystore.pass'] ?= 'ryba123'
      ranger.admin.site['ranger.service.https.attrib.keystore.keyalias'] ?= @config.shortname

# Ranger Admin Databases
Configures the Ranger WEBUi (policymanager) database. For now only mysql is supported.

      ranger.admin.install['DB_FLAVOR'] ?= 'MYSQL' # we support only mysql for now
      switch ranger.admin.install['DB_FLAVOR'].toLowerCase()
        when 'mysql'
          ranger.admin.install['SQL_CONNECTOR_JAR'] ?= '/usr/hdp/current/ranger-admin/lib/mysql-connector-java.jar'
          # not setting these properties on purpose, we manage manually databases inside mysql
          ranger.admin.install['db_root_user'] = db_admin.username
          ranger.admin.install['db_root_password'] ?= db_admin.password
          if not ranger.admin.install['db_root_user'] and not ranger.admin.install['db_root_password']
          then throw new Error "account with privileges for creating database schemas and users is required"
          ranger.admin.install['db_host'] ?=  db_admin.host
          #Ranger Policy Database
          throw new Error "mysql host not specified" unless ranger.admin.install['db_host']
          ranger.admin.install['db_name'] ?= 'ranger'
          ranger.admin.install['db_user'] ?= 'rangeradmin'
          ranger.admin.install['db_password'] ?= 'rangeradmin123'
          #Ranger Audit Database
          ranger.admin.install['audit_db_name'] ?= 'ranger_audit'
          ranger.admin.install['audit_db_user'] ?= 'rangerlogger'
          ranger.admin.install['audit_db_password'] ?= 'rangerlogger123'
        else throw new Error 'For now only mysql engine is supported'


# Ranger Admin Policymanager Access
Defined how Ranger authenticates users (the xusers)  to the webui. By default
only users created within the webui are allowed.

      protocol = if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] == 'true' then 'https' else 'http'
      port = ranger.admin.site["ranger.service.#{protocol}.port"]
      ranger.admin.install['policymgr_external_url'] ?= "#{protocol}://#{@config.host}:#{port}"
      ranger.admin.install['policymgr_http_enabled'] ?= 'true'
      ranger.admin.install['unix_user'] ?= ranger.user.name
      ranger.admin.install['unix_group'] ?= ranger.group.name
      #Policy Admin Tool Authentication
      # NONE enables only users created within the Policy Admin Tool 
      ranger.admin.install['authentication_method'] ?= 'NONE'
      unix_props = ['remoteLoginEnabled','authServiceHostName','authServicePort']
      ldap_props = ['xa_ldap_url','xa_ldap_userDNpattern','xa_ldap_groupSearchBase',
      'xa_ldap_groupSearchFilter','xa_ldap_groupRoleAttribute']
      active_dir_props = ['xa_ldap_ad_domain','xa_ldap_ad_url']
      switch ranger.admin.install['authentication_method']
        when 'UNIX'
          throw new Error "missing property: #{prop}" unless ranger.admin.install[prop] for prop in unix_props
        when 'LDAP'
          if !ranger.admin.install['xa_ldap_url']?
            [opldp_srv_ctx] = @contexts 'masson/core/openldap_server', require("#{__dirname}/../../node_modules/masson/core/openldap_server/configure").handler
            throw Error 'no openldap server configured' unless opldp_srv_ctx?
            {openldap_server} = opldp_srv_ctx.config
            ranger.admin.install['xa_ldap_url'] ?= "#{openldap_server.uri}"
            ranger.admin.install['xa_ldap_userDNpattern'] ?= "cn={0},ou=users,#{openldap_server.suffix}"
            ranger.admin.install['xa_ldap_groupSearchBase'] ?=  "ou=groups,#{openldap_server.suffix}"
            ranger.admin.install['xa_ldap_groupSearchFilter'] ?= "(uid={0},ou=groups,#{openldap_server.suffix})"
            ranger.admin.install['xa_ldap_groupRoleAttribute'] ?= 'cn'
            ranger.admin.install['xa_ldap_userSearchFilter'] ?= '(uid={0})'
            ranger.admin.install['xa_ldap_base_dn'] ?= "#{openldap_server.suffix}"
            ranger.admin.install['xa_ldap_bind_dn'] ?= "#{openldap_server.root_dn}"
            ranger.admin.install['xa_ldap_bind_password'] ?= "#{openldap_server.root_password}"
          throw new Error "missing property: #{prop}" unless ranger.admin.install[prop] for prop in ldap_props
        when 'ACTIVE_DIRECTORY'
          throw new Error "missing property: #{prop}" unless ranger.admin.install[prop] for prop in active_dir_props
        when 'NONE'
          break;
        else
          throw new Error 'selected authentication_method is not supported by Ranger'

## Ranger Environment

      ranger.admin.heap_size ?= '256m'
      ranger.admin.opts ?= {}
      # ranger.admin.opts['javax.net.ssl.trustStore'] ?= '/etc/hadoop/conf/truststore'
      # ranger.admin.opts['javax.net.ssl.trustStorePassword'] ?= 'ryba123'

# Ranger PLUGINS
Plugins are HDP Packages which once enabled, allow Ranger to manage ACL for services.
For now Ranger support policy management for:
- HDFS
- YARN
- HBASE
- KAFKA
- Hive 
- SOLR 
Plugins should be configured before the service is started and/or configured.
Ryba injects function to the different contexts.

      ranger.plugins ?= {}      
      ranger.plugins.principal ?= "#{ranger.user.name}@#{realm}"
      ranger.plugins.password ?= 'ranger123'

## HDFS Plugin
For the HDFS plugin, the executed script already create the hdfs user to ranger admin
as external.

      ranger.plugins.hdfs_enabled ?= if nn_ctxs.length > 0 then true else false
      if ranger.plugins.hdfs_enabled 
        throw Error 'Need HDFS to enable ranger HDFS Plugin' unless nn_ctxs.length > 1
        for nn_ctx in nn_ctxs
          # Commun Configuration
          nn_ctx.config.ryba.ranger ?= {}
          nn_ctx.config.ryba.ranger.user = ranger.user
          nn_ctx.config.ryba.ranger.group = ranger.group
          nn_ctx.config.ryba.hdfs.namenode_opts += " -Djavax.net.ssl.trustStore=#{nn_ctx.config.ryba.ssl_server['ssl.server.truststore.location']} "
          nn_ctx.config.ryba.hdfs.namenode_opts += " -Djavax.net.ssl.trustStorePassword=#{nn_ctx.config.ryba.ssl_server['ssl.server.truststore.password']}"
          # HDFS Plugin configuration
          hdfs_plugin = nn_ctx.config.ryba.ranger.hdfs_plugin ?= {}
          hdfs_plugin.install ?= {}
          hdfs_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

### HDFS Plugin Policy Admin Tool
The repository name should match the reposity name in web ui.
The properties can be found [here][hdfs-repository]

          hdfs_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
          hdfs_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hdfs'
          hdfs_plugin.service_repo ?=
            'configs': 
              'password': hdfs.krb5_user.principal
              'username': hdfs.krb5_user.password
              'fs.default.name': core_site['fs.defaultFS']
              'hadoop.security.authentication': core_site['hadoop.security.authentication']
              'dfs.namenode.kerberos.principal': nn_ctxs[0].config.ryba.hdfs.site['dfs.namenode.kerberos.principal']
              'dfs.datanode.kerberos.principal': dn_ctxs[0].config.ryba.hdfs.site['dfs.datanode.kerberos.principal']
              'hadoop.rpc.protection': core_site['hadoop.rpc.protection']
              'hadoop.security.authorization': core_site['hadoop.security.authorization']
              'hadoop.security.auth_to_local': core_site['hadoop.security.auth_to_local']   
              'commonNameForCertificate': ''           
            'description': 'HDFS Repo'
            'isEnabled': true
            'name': hdfs_plugin.install['REPOSITORY_NAME']
            'type': 'hdfs'

### HDFS Plugin Audit (database storage)

          hdfs_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'true'
          if hdfs_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
            hdfs_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
            switch hdfs_plugin.install['XAAUDIT.DB.FLAVOUR']
              when 'MYSQL'
                hdfs_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
                hdfs_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
                hdfs_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
                hdfs_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
                hdfs_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
              when 'ORACLE'
                throw Error 'Ryba does not support ORACLE Based Ranger Installation'
              else
                throw Error "Apache Ranger does not support chosen DB FLAVOUR"

### HDFS Plugin Audit (HDFS Storage)
Configure Audit to HDFS

          # V3 configuration
          hdfs_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
          hdfs_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
          hdfs_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/hdfs/audit/hdfs/spool'

          hdfs_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
          if hdfs_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
            hdfs_plugin.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/%app-type%/%time:yyyyMMdd%"
            hdfs_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= '/var/log/ranger/%app-type%/audit'
            hdfs_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= '/var/log/ranger/%app-type%/archive'
            hdfs_plugin.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
            hdfs_plugin.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
            hdfs_plugin.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
            hdfs_plugin.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
            hdfs_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
            hdfs_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
            hdfs_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
            hdfs_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

### HDFS Plugin Audit (SOLR Storage)
Configure Audit to SOLR

          if ranger.admin.install['audit_store'] is 'solr'
            hdfs_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
            hdfs_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
            hdfs_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
            hdfs_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
            hdfs_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
            hdfs_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
            hdfs_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/hdfs/audit/solr/spool'


### HDFS Plugin SSL

          if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
            hdfs_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= nn_ctx.config.ryba.ssl_server['ssl.server.keystore.location']
            hdfs_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= nn_ctx.config.ryba.ssl_server['ssl.server.keystore.password']
            hdfs_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= nn_ctx.config.ryba.ssl_server['ssl.server.truststore.location']
            hdfs_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= nn_ctx.config.ryba.ssl_server['ssl.server.truststore.password']

          nn_ctx
          .after
            type: 'render'
            target: "#{nn_ctx.config.ryba.hdfs.nn.conf_dir}/hadoop-env.sh"
            handler: -> 
              @call 'ryba/ranger/admin/plugin_hdfs'
          .before
            type: 'service_start'
            name: 'hadoop-hdfs-namenode'
            handler: -> 
              @wait_execute
                cmd: """
                  curl --fail -H \"Content-Type: application/json\"   -k -X GET  \ 
                  -u admin:#{ranger.admin.password} \
                  \"#{hdfs_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{hdfs_plugin.install['REPOSITORY_NAME']}\"
                """
                code_skipped: 22
              @service_restart
                header: 'Ranger scheduled HDFS NameNode restart'
                name: 'hadoop-hdfs-namenode'
                if_exists: '/etc/init.d/hadoop-hdfs-namenode'


## YARN Plugin

      ranger.plugins.yarn_enabled ?= if rm_ctxs.length > 0 then true else false
      if ranger.plugins.yarn_enabled 
        throw Error 'Need YARN to enable ranger YARN Plugin' unless rm_ctxs.length > 1
        # Ranger Yarn User
        ranger.users['yarn'] ?= 
          "name": 'yarn'
          "firstName": 'yarn'
          "lastName": 'hadoop'
          "emailAddress": 'yarn@hadoop.ryba'
          "password": 'yarn123'
          'userSource': 1
          'userRoleList': ['ROLE_USER']
          'groups': []
          'status': 1
        for rm_ctx in rm_ctxs
          # Commun Configuration
          rm_ctx.config.ryba.ranger ?= {}
          rm_ctx.config.ryba.ranger.user ?= ranger.user
          rm_ctx.config.ryba.ranger.group ?= ranger.group
          # YARN Plugin configuration
          yarn_plugin = rm_ctx.config.ryba.ranger.yarn_plugin ?= {}  
          yarn_plugin.principal ?= ranger.plugins.principal
          yarn_plugin.password ?= ranger.plugins.password        
          yarn_plugin.install ?= {}
          yarn_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

### YARN Policy Admin Tool
The repository name should match the reposity name in web ui.

          yarn_url = if rm_ctxs[0].config.ryba.yarn.rm.site['yarn.http.policy'] is 'HTTP_ONLY'
          then "http://#{rm_ctxs[0].config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.http.address.#{rm_ctxs[0].config.shortname}"]}"
          else "https://#{rm_ctxs[0].config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.https.address.#{rm_ctxs[0].config.shortname}"]}"
          yarn_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
          yarn_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-yarn'
          yarn_plugin.service_repo ?=
            'configs': 
              'password': hdfs.krb5_user.principal
              'username': hdfs.krb5_user.principal
              'yarn.url': yarn_url
            'description': 'YARN Repo'
            'isEnabled': true
            'name': yarn_plugin.install['REPOSITORY_NAME']
            'type': 'yarn'

### YARN Plugin audit

          yarn_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
          if yarn_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
            yarn_plugin.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/%app-type%/%time:yyyyMMdd%"
            yarn_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= '/var/log/ranger/%app-type%/audit'
            yarn_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= '/var/log/ranger/%app-type%/archive'
            yarn_plugin.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
            yarn_plugin.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
            yarn_plugin.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
            yarn_plugin.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
            yarn_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
            yarn_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
            yarn_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
            yarn_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

### YARN Audit (HDFS Storage)

          # AUDIT TO HDFS
          yarn_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
          yarn_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
          yarn_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/yarn/audit/hdfs/spool'

### YARN Audit (database storage)

          yarn_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'true'
          if yarn_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
            yarn_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
            switch yarn_plugin.install['XAAUDIT.DB.FLAVOUR']
              when 'MYSQL'
                yarn_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
                yarn_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
                yarn_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
                yarn_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
                yarn_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
              when 'ORACLE'
                throw Error 'Ryba does not support ORACLE Based Ranger Installation'
              else
                throw Error "Apache Ranger does not support chosen DB FLAVOUR"        

### YARN Audit (to SOLR)

          if ranger.admin.install['audit_store'] is 'solr'
            yarn_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
            yarn_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
            yarn_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
            yarn_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
            yarn_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
            yarn_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
            yarn_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/yarn/audit/solr/spool'

### YARN Plugin SSL
Used only if SSL is enabled between Policy Admin Tool and Plugin

          if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
            yarn_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= rm_ctx.config.ryba.ssl_server['ssl.server.keystore.location']
            yarn_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= rm_ctx.config.ryba.ssl_server['ssl.server.keystore.password']
            yarn_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= rm_ctx.config.ryba.ssl_client['ssl.client.truststore.location']
            yarn_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= rm_ctx.config.ryba.ssl_client['ssl.client.truststore.password']

### YARN ResourceManager Enable      

          rm_ctx.config.ryba.ranger.user = ranger.user
          rm_ctx.config.ryba.ranger.group = ranger.group
          rm_ctx
          .after
            type: 'hconfigure'
            target: "#{rm_ctx.config.ryba.yarn.rm.conf_dir}/yarn-site.xml"
            handler: -> 
              @call 'ryba/ranger/admin/plugin_yarn'
          .before
            type: 'service_start'
            name: 'hadoop-yarn-resourcemanager'
            handler: -> 
              @wait_execute
                cmd: """
                  curl --fail -H \"Content-Type: application/json\"   -k -X GET \ 
                  -u admin:#{ranger.admin.password} \
                  \"#{yarn_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{yarn_plugin.install['REPOSITORY_NAME']}\"
                """
                code_skipped: 22
              @service_restart 
                header: 'Ranger scheduled ResourceManager restart'
                if_exec: 'service hadoop-yarn-resourcemanager status'
                name: 'hadoop-yarn-resourcemanager'

### YARN NodeManager Enable

        for nm_ctx in nm_ctxs
          nm_ctx
          .before
            type: 'service_start'
            name: 'hadoop-yarn-nodemanager'
            handler: ->
              @wait_execute
                cmd: """
                  curl --fail -H \"Content-Type: application/json\"   -k -X GET  \ 
                  -u admin:#{ranger.admin.password} \
                  \"#{yarn_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{yarn_plugin.install['REPOSITORY_NAME']}\"
                """
                code_skipped: [22,7]
              @service_restart
                name: 'hadoop-yarn-nodemanager'

## HBase Plugin

      ranger.plugins.hbase_enabled ?= if hm_ctxs.length > 0 then true else false
      if ranger.plugins.hbase_enabled 
        throw Error 'Need HBase to enable ranger HBase Plugin' unless rm_ctxs.length > 1
        # Ranger HBase Webui xuser
        ranger.users['hbase'] ?=
          "name": 'hbase'
          "firstName": ''
          "lastName": 'hadoop'
          "emailAddress": 'hbase@hadoop.ryba'
          "password": 'hbase123'
          'userSource': 1
          'userRoleList': ['ROLE_USER']
          'groups': []
          'status': 1
        ctxs = []
        ctxs.push hm_ctxs...
        ctxs.push rs_ctxs...
        ctxs.push hbcli_ctxs...
        for ctx in ctxs
          # Commun Configuration
          ctx.config.ryba.ranger ?= {}
          ctx.config.ryba.ranger.user = @config.ryba.ranger.user
          ctx.config.ryba.ranger.group = @config.ryba.ranger.group
          # HBase Plugin configuration
          hbase_plugin = ctx.config.ryba.ranger.hbase_plugin ?= {}
          hbase_plugin.policy_name ?= "Ranger-Ryba-HBase-Policy"
          hbase_plugin.install ?= {}
          hbase_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

### HBase Policy Admin Tool
The repository name should match the reposity name in web ui.

          hbase_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
          hbase_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hbase'
          hbase_plugin.service_repo ?=
            'configs': 
              'password': hm_ctxs[0].config.ryba.hbase.admin.principal
              'username': hm_ctxs[0].config.ryba.hbase.admin.password
              'hadoop.security.authorization': core_site['hadoop.security.authorization']
              'hbase.master.kerberos.principal': hm_ctxs[0].config.ryba.hbase.master.site['hbase.master.kerberos.principal']
              'hadoop.security.authentication': core_site['hadoop.security.authentication']
              'hbase.security.authentication': hm_ctxs[0].config.ryba.hbase.master.site['hbase.security.authentication']
              'hbase.zookeeper.property.clientPort': hm_ctxs[0].config.ryba.hbase.master.site['hbase.zookeeper.property.clientPort']
              'hbase.zookeeper.quorum': hm_ctxs[0].config.ryba.hbase.master.site['hbase.zookeeper.quorum']
              'zookeeper.znode.parent': hm_ctxs[0].config.ryba.hbase.master.site['zookeeper.znode.parent']
            'description': 'HBase Repo'
            'isEnabled': true
            'name': hbase_plugin.install['REPOSITORY_NAME']
            'type': 'hbase'
          hbase_plugin.install['XAAUDIT.SUMMARY.ENABLE'] ?= 'true'
          hbase_plugin.install['UPDATE_XAPOLICIES_ON_GRANT_REVOKE'] ?= 'true'

### HBase Audit (HDFS V3 properties)

          # V3 Configuration
          hbase_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
          if hbase_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
            hbase_plugin.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/%app-type%/%time:yyyyMMdd%"
            hbase_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= '/var/log/ranger/%app-type%/audit'
            hbase_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= '/var/log/ranger/%app-type%/archive'
            hbase_plugin.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
            hbase_plugin.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
            hbase_plugin.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
            hbase_plugin.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
            hbase_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
            hbase_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
            hbase_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
            hbase_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

### HBase Audit (HDFS Storage)

          # AUDIT TO HDFS
          hbase_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
          hbase_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
          hbase_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/hbase/audit/hdfs/spool'

### HBase Audit (database storage)

          hbase_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'true'
          if hbase_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
            hbase_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
            switch hbase_plugin.install['XAAUDIT.DB.FLAVOUR']
              when 'MYSQL'
                hbase_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
                hbase_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
                hbase_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
                hbase_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
                hbase_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
              when 'ORACLE'
                throw Error 'Ryba does not support ORACLE Based Ranger Installation'
              else
                throw Error "Apache Ranger does not support chosen DB FLAVOUR" 

### HBase Audit (to SOLR)

          if ranger.admin.install['audit_store'] is 'solr'
            hbase_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
            hbase_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
            hbase_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
            hbase_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
            hbase_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
            hbase_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
            hbase_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/hbase/audit/solr/spool'

### HBase Plugin Execution

        # Master Servers
        for hm_ctx in hm_ctxs
          if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
            hm_ctx.config.ryba.ranger.hbase_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= hm_ctx.config.ryba.ssl_server['ssl.server.keystore.location']
            hm_ctx.config.ryba.ranger.hbase_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= hm_ctx.config.ryba.ssl_server['ssl.server.keystore.password']
            hm_ctx.config.ryba.ranger.hbase_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= hm_ctx.config.ryba.ssl_client['ssl.client.truststore.location']
            hm_ctx.config.ryba.ranger.hbase_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= hm_ctx.config.ryba.ssl_client['ssl.client.truststore.password']
          hm_ctx
          .after
            type: 'hconfigure'
            target: "#{hm_ctx.config.ryba.hbase.master.conf_dir}/hbase-site.xml"
            handler: -> 
              @call 'ryba/ranger/admin/plugin_hbase'
          hm_ctx
          .before
            type: 'service_start'
            name: 'hbase-master'
            if_exists: '/etc/init.d/hbase-master'
            handler: ->
              @wait_execute
                header: 'Wait HBase Ranger repository'
                cmd: """
                  curl --fail -H \"Content-Type: application/json\" -k -X GET  \ 
                  -u admin:#{ranger.admin.password} \
                  \"#{hbase_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{hbase_plugin.install['REPOSITORY_NAME']}\"
                """
                code_skipped: 22
              @service_restart
                header: 'Ranger scheduled HBase Master restart'
                if_exec: 'service hbase-master status'
                name: 'hbase-master'

        # Regionservers
        for rs_ctx in rs_ctxs
          if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
            rs_ctx.config.ryba.ranger.hbase_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= rs_ctx.config.ryba?.ssl_server?['ssl.server.keystore.location']
            rs_ctx.config.ryba.ranger.hbase_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= rs_ctx.config.ryba?.ssl_server?['ssl.server.keystore.password']
            rs_ctx.config.ryba.ranger.hbase_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= rs_ctx.config.ryba?.ssl_client?['ssl.client.truststore.location']
            rs_ctx.config.ryba.ranger.hbase_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= rs_ctx.config.ryba?.ssl_client?['ssl.client.truststore.password']
          rs_ctx
          .after
            type: 'hconfigure'
            target: "#{rs_ctx.config.ryba.hbase.rs.conf_dir}/hbase-site.xml"
            handler: -> 
              @call 'ryba/ranger/admin/plugin_hbase'
          .before
            type: 'service_start'
            name: 'hbase-regionserver'
            if_exists: '/etc/init.d/hbase-regionserver'
            handler: ->
              @wait_execute
                cmd: """
                  curl --fail -H \"Content-Type: application/json\"   -k -X GET  \ 
                  -u admin:#{ranger.admin.password} \
                  \"#{hbase_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{hbase_plugin.install['REPOSITORY_NAME']}\"
                """
                code_skipped: [22,7]
              @service_restart
                header: 'Ranger scheduled HBase Regionserver restart'
                if_exec: 'service hbase-regionserver status'
                name: 'hbase-regionserver'

## Kafka Plugin

      #de-activating now 
      #https://mail-archives.apache.org/mod_mbox/incubator-ranger-user/201605.mbox/%3C363AE5BD-D796-425B-89C9-D481F6E74BAF@apache.org%3E
      ranger.plugins.kafka_enabled = true
      ranger.plugins.kafka_enabled ?= if kb_ctxs.length > 0 then true else false
      if ranger.plugins.kafka_enabled 
        throw Error 'Need at least one kafka broker to enable ranger kafka Plugin' unless kb_ctxs.length > 1
        for kb_ctx in kb_ctxs
          # Commun Configuration
          kb_ctx.config.ryba.ranger ?= {}
          kb_ctx.config.ryba.ranger.user = ranger.user
          kb_ctx.config.ryba.ranger.group = ranger.group
          # HDFS Plugin configuration
          kafka_plugin = kb_ctx.config.ryba.ranger.kafka_plugin ?= {}
          kb_ctx.config.ryba.kafka.broker.config['authorizer.class.name'] = 'org.apache.ranger.authorization.kafka.authorizer.RangerKafkaAuthorizer'
          kafka_plugin.install ?= {}
          kafka_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

### Kafka Policy Admin Tool
The repository name should match the reposity name in web ui.
The properties can be found [here][kafka-repository]

          kafka_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
          kafka_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-kafka'
          kafka_plugin.service_repo ?=
            'configs': 
              'password': kb_ctxs[0].config.ryba.kafka.admin.password
              'username': kb_ctxs[0].config.ryba.kafka.admin.principal
              'hadoop.security.authentication': core_site['hadoop.security.authentication']
              'zookeeper.connect': kb_ctxs[0].config.ryba.kafka.broker.config['zookeeper.connect'].join(',')
              'commonNameForCertificate': ''           
            'description': 'kafka Repository'
            'isEnabled': true
            'name': kafka_plugin.install['REPOSITORY_NAME']
            'type': 'kafka'

### Kafka Audit (database storage)

          #Should audit be summarized at source
          kafka_plugin.install['XAAUDIT.SUMMARY.ENABLE'] ?= 'true'
          kafka_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'true'
          if kafka_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
            kafka_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
            switch kafka_plugin.install['XAAUDIT.DB.FLAVOUR']
              when 'MYSQL'
                kafka_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
                kafka_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
                kafka_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
                kafka_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
                kafka_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
              when 'ORACLE'
                throw Error 'Ryba does not support ORACLE Based Ranger Installation'
              else
                throw Error "Apache Ranger does not support chosen DB FLAVOUR"

### Kafka Audit (HDFS Storage)

          # V3 configuration
          kafka_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
          kafka_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
          kafka_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/hdfs/audit/kafka/spool'

          kafka_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
          if kafka_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
            kafka_plugin.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/%app-type%/%time:yyyyMMdd%"
            kafka_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= '/var/log/ranger/%app-type%/audit'
            kafka_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= '/var/log/ranger/%app-type%/archive'
            kafka_plugin.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
            kafka_plugin.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
            kafka_plugin.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
            kafka_plugin.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
            kafka_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
            kafka_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
            kafka_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
            kafka_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

### Kafka Audit (to SOLR)

          if ranger.admin.install['audit_store'] is 'solr'
            kafka_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
            kafka_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
            kafka_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
            kafka_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
            kafka_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
            kafka_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
            kafka_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/kafka/audit/solr/spool'

### Kafka Plugin SSL

          if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
            kafka_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= kb_ctx.config.ryba.ssl_server['ssl.server.keystore.location']
            kafka_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= kb_ctx.config.ryba.ssl_server['ssl.server.keystore.password']
            kafka_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= kb_ctx.config.ryba.ssl_client['ssl.client.truststore.location']
            kafka_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= kb_ctx.config.ryba.ssl_client['ssl.client.truststore.password']

### Kafka Plugin Execution   

          kb_ctx
          .after
            type: 'write'
            target: "#{kb_ctx.config.ryba.kafka.broker.conf_dir}/server.properties"
            handler: -> 
              @call 'ryba/ranger/admin/plugin_kafka'

          kb_ctx
          .before
            type: 'service_start'
            name: 'kafka-broker'
          , handler: -> 
              @wait_execute
                cmd: """
                  curl --fail -H \"Content-Type: application/json\"   -k -X GET  \ 
                  -u admin:#{ranger.admin.password} \
                  \"#{kafka_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{kafka_plugin.install['REPOSITORY_NAME']}\"
                """
                code_skipped: [22,7]
              @service_restart 
                header: 'Ranger scheduled Kafka Broker restart'
                if_exec: 'service kafka-broker status'
                name: 'kafka-broker'

## Ranger HIVE Plugin
Ranger Hive plugin runs inside Hiveserver JVM

      ranger.plugins.hive_enabled ?= if hive_ctxs.length > 0 then true else false
      if ranger.plugins.hive_enabled 
        throw Error 'Need Hive Server2 to enable ranger Hive Plugin' unless hive_ctxs.length > 1
        # Ranger Yarn User
        ranger.users['hive'] ?=
          "name": 'hive'
          "firstName": 'hive'
          "lastName": 'hadoop'
          "emailAddress": 'hive@hadoop.ryba'
          'userSource': 1
          'userRoleList': ['ROLE_USER']
          'groups': []
          'status': 1
        port = if hive_ctxs[0].config.ryba.hive.site['hive.server2.transport.mode'] is 'http'
        then hive_ctxs[0].config.ryba.hive.site['hive.server2.thrift.http.port']
        else hive_ctxs[0].config.ryba.hive.site['hive.server2.thrift.port']
        hive_url = 'jdbc:hive2://'
        hive_url += "#{hive_ctxs[0].config.host}:#{port}/"
        hive_url += ";principal=#{hive_ctxs[0].config.ryba.hive.site['hive.server2.authentication.kerberos.principal']}" if @config.ryba.security is 'kerberos'
        if hive_ctxs[0].config.ryba.hive.site['hive.server2.use.SSL'] is 'true'
          hive_url += ";ssl=true"
          hive_url += ";sslTrustStore=#{@config.ryba.ssl_client['ssl.client.truststore.location']}"
          hive_url += ";trustStorePassword=#{@config.ryba.ssl_client['ssl.client.truststore.password']}"
        if hive_ctxs[0].config.ryba.hive.site['hive.server2.transport.mode'] is 'http'
          hive_url += ";transportMode=#{hive_ctxs[0].config.ryba.hive.site['hive.server2.transport.mode']}"
          hive_url += ";httpPath=#{hive_ctxs[0].config.ryba.hive.site['hive.server2.thrift.http.path']}"
        for hive_ctx in hive_ctxs
          # Commun Configuration
          hive_ctx.config.ryba.ranger ?= {}
          hive_ctx.config.ryba.ranger.user ?= ranger.user
          hive_ctx.config.ryba.ranger.group ?= ranger.group
          # YARN Plugin configuration
          hive_plugin = hive_ctx.config.ryba.ranger.hive_plugin ?= {}  
          hive_plugin.principal ?= ranger.plugins.principal
          hive_plugin.password ?= ranger.plugins.password        
          hive_plugin.install ?= {}
          hive_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
          # Should Hive GRANT/REVOKE update XA policies?
          hive_plugin.install['UPDATE_XAPOLICIES_ON_GRANT_REVOKE'] ?= 'true'
          hive_plugin.install['CUSTOM_USER'] ?= "#{hive_ctxs[0].config.ryba.hive.user.name}"
          hive_plugin.install['CUSTOM_GROUP'] ?= "#{hadoop_group.name}"

### HIVE Policy Admin Tool
The repository name should match the reposity name in web ui.

          hive_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
          hive_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hive'
          hive_plugin.service_repo ?=  
            'description': 'Hive Repo'
            'isEnabled': true
            'name': hive_plugin.install['REPOSITORY_NAME']
            'type': 'hive'
            'configs':
              'username': hive_plugin.principal 
              'password': hive_plugin.password
              'jdbc.driverClassName': 'org.apache.hive.jdbc.HiveDriver'
              'jdbc.url': "#{hive_url}"
              "commonNameForCertificate": ''

### HIVE Plugin audit

          hive_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
          if hive_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
            hive_plugin.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/%app-type%/%time:yyyyMMdd%"
            hive_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= '/var/log/ranger/%app-type%/audit'
            hive_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= '/var/log/ranger/%app-type%/archive'
            hive_plugin.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
            hive_plugin.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
            hive_plugin.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
            hive_plugin.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
            hive_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
            hive_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
            hive_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
            hive_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

### HIVE Audit (HDFS Storage)

          # AUDIT TO HDFS
          hive_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
          hive_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
          hive_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/hive/audit/hdfs/spool'

### HIVE Audit (database storage)

          hive_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'true'
          if hive_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
            hive_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
            switch hive_plugin.install['XAAUDIT.DB.FLAVOUR']
              when 'MYSQL'
                hive_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
                hive_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
                hive_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
                hive_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
                hive_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
              when 'ORACLE'
                throw Error 'Ryba does not support ORACLE Based Ranger Installation'
              else
                throw Error "Apache Ranger does not support chosen DB FLAVOUR"        

### HIVE Audit (to SOLR)

          if ranger.admin.install['audit_store'] is 'solr'
            hive_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
            hive_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
            hive_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
            hive_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
            hive_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
            hive_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
            hive_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/hive/audit/solr/spool'

### HIVE Plugin SSL
Used only if SSL is enabled between Policy Admin Tool and Plugin

          if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
            hive_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= hive_ctx.config.ryba.ssl_server['ssl.server.keystore.location']
            hive_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= hive_ctx.config.ryba.ssl_server['ssl.server.keystore.password']
            hive_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= hive_ctx.config.ryba.ssl_client['ssl.client.truststore.location']
            hive_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= hive_ctx.config.ryba.ssl_client['ssl.client.truststore.password']

### HIVE ResourceManager Enable      

          hive_ctx.config.ryba.ranger.user = ranger.user
          hive_ctx.config.ryba.ranger.group = ranger.group
          hive_ctx
          .after
            type: 'render'
            header: 'Hive Server2 Env'
            target: "#{hive_ctx.config.ryba.hive.server2.conf_dir}/hive-env.sh"
            handler: -> 
              @call 'ryba/ranger/admin/plugin_hive'
          .before
            type: 'service_start'
            name: 'hive-server2'
            handler: -> 
              @wait_execute
                cmd: """
                  curl --fail -H \"Content-Type: application/json\"   -k -X GET \ 
                  -u admin:#{ranger.admin.password} \
                  \"#{hive_plugin.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{hive_plugin.install['REPOSITORY_NAME']}\"
                """
                code_skipped: 22
              @service_restart 
                header: 'Ranger scheduled Hive Server2 restart'
                if_exec: 'service hive-server2 status'
                name: 'hive-server2'

## Dependencies

    quote = require 'regexp-quote'

[ranger-2.4.0]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/configure-the-ranger-policy-administration-authentication-moades.html)
[ranger-ssl]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_Security_Guide/content/configure_non_ambari_ranger_ssl.html) 
[ranger-ldap]:(https://community.hortonworks.com/articles/16696/ranger-ldap-integration.html)
[ranger-api-object]:(https://community.hortonworks.com/questions/10826/rest-api-url-to-configure-ranger-objects.html)
[ranger-solr]:(https://community.hortonworks.com/articles/15159/securing-solr-collections-with-ranger-kerberos.html)
[hdfs-repository]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_Ranger_User_Guide/content/hdfs_repository.html)
[hdfs-repository-0.4.1]:(https://cwiki.apache.org/confluence/display/RANGER/REST+APIs+for+Policy+Management?src=contextnavpagetreemode)
[user-guide-0.5]:(https://cwiki.apache.org/confluence/display/RANGER/Apache+Ranger+0.5+-+User+Guide)
