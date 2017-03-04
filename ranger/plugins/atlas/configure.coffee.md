
# Ranger Atlas Plugin Configure
Ranger Atlas plugin runs inside Atlas Metadata server's JVM


    module.exports = ->
      atlas_ctxs = @contexts 'ryba/atlas'
      [ranger_admin_ctx] = @contexts 'ryba/ranger/admin'
      return unless ranger_admin_ctx?
      {ryba} = @config
      {realm, ssl, core_site, hdfs, hadoop_group, hadoop_conf_dir} = ryba
      ranger = ranger_admin_ctx.config.ryba.ranger ?= {}
      ranger.plugins.atlas_enabled ?= if atlas_ctxs.length > 0 then true else false
      if ranger.plugins.atlas_enabled
        throw Error 'Need Atlas to enable ranger Atlas Plugin' unless atlas_ctxs.length > 0
        # Ranger Yarn User
        ranger.users['atlas'] ?=
          "name": 'atlas'
          "firstName": 'atlas'
          "lastName": 'hadoop'
          "emailAddress": 'atlas@hadoop.ryba'
          'userSource': 1
          'userRoleList': ['ROLE_USER']
          'groups': []
          'status': 1
        # Atlas Plugin configuration
        atlas_plugin = @config.ryba.ranger.atlas_plugin ?= {}
        atlas_plugin.principal ?= ranger.plugins.principal
        atlas_plugin.password ?= ranger.plugins.password
        atlas_plugin.install ?= {}
        atlas_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
        # Should Atlas GRANT/REVOKE update XA policies?
        atlas_plugin.install['UPDATE_XAPOLICIES_ON_GRANT_REVOKE'] ?= 'true'
        atlas_plugin.install['CUSTOM_USER'] ?= "#{@config.ryba.atlas.user.name}"
        atlas_plugin.install['CUSTOM_GROUP'] ?= "#{hadoop_group.name}"

### Atlas Policy Admin Tool
The repository name should match the reposity name in web ui.

        atlas_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
        atlas_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-atlas'
        atlas_plugin.service_repo ?=  
          'description': 'Atlas Repo'
          'isEnabled': true
          'name': atlas_plugin.install['REPOSITORY_NAME']
          'type': 'atlas'
          'configs':
            'atlas.rest.address': @config.ryba.atlas.application.properties['atlas.rest.address']
            'policy.download.auth.users': "#{@config.ryba.atlas.user.name}" #from ranger 0.6
            'tag.download.auth.users': "#{@config.ryba.atlas.user.name}"
        if @config.ryba.atlas.application.properties['atlas.authentication.method'] is 'kerberos'
          atlas_plugin.service_repo['configs']['username'] ?= @config.ryba.atlas.admin_principal
          atlas_plugin.service_repo['configs']['password'] ?= @config.ryba.atlas.admin_password
        else
          throw Error 'Authentication not support for ranger - atlas - plugin'
          

### Atlas Plugin audit

        atlas_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
        if atlas_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
          atlas_plugin.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/%app-type%/%time:yyyyMMdd%"
          atlas_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= '/var/log/ranger/%app-type%/audit'
          atlas_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= '/var/log/ranger/%app-type%/archive'
          atlas_plugin.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
          atlas_plugin.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
          atlas_plugin.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
          atlas_plugin.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
          atlas_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
          atlas_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
          atlas_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
          atlas_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

### Atlas Audit (HDFS Storage)

        # AUDIT TO HDFS
        atlas_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        atlas_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
        atlas_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{@config.ryba.atlas.log_dir}/audit/hdfs/spool"

### Atlas Audit (database storage)

        #Deprecated
        atlas_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
        if atlas_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
          atlas_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
          switch atlas_plugin.install['XAAUDIT.DB.FLAVOUR']
            when 'MYSQL'
              atlas_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
              atlas_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
              atlas_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
              atlas_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
              atlas_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
            when 'ORACLE'
              throw Error 'Ryba does not support ORACLE Based Ranger Installation'
            else
              throw Error "Apache Ranger does not support chosen DB FLAVOUR"
        else
            atlas_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
            atlas_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
            atlas_plugin.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
            atlas_plugin.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

### Atlas Audit (to SOLR)

        if ranger.admin.install['audit_store'] is 'solr'
          atlas_plugin.audit ?= {}
          atlas_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
          atlas_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
          atlas_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
          atlas_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
          atlas_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
          atlas_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
          atlas_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{@config.ryba.atlas.log_dir}/audit/solr/spool"
          atlas_plugin.audit['xasecure.audit.destination.solr.force.use.inmemory.jaas.config'] ?= 'true'
          atlas_plugin.audit['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
          atlas_plugin.audit['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
          atlas_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
          atlas_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
          atlas_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
          atlas_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
          atlas_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
          atlas_princ = @config.ryba.atlas.application.properties['atlas.authentication.principal'].replace '_HOST', @config.host
          atlas_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.principal'] ?= atlas_princ
          atlas_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= @config.ryba.atlas.application.properties['atlas.authentication.keytab'] 

### Atlas Plugin SSL
Used only if SSL is enabled between Policy Admin Tool and Plugin

        if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
          atlas_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= @config.ryba.ssl_server['ssl.server.keystore.location']
          atlas_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= @config.ryba.ssl_server['ssl.server.keystore.password']
          atlas_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= @config.ryba.ssl_client['ssl.client.truststore.location']
          atlas_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= @config.ryba.ssl_client['ssl.client.truststore.password']

## Merge atlas_plugin conf to ranger admin

        ranger_admin_ctx.config.ryba.ranger.atlas_plugin = merge atlas_plugin

## Dependencies

    {merge} = require 'nikita/lib/misc'
