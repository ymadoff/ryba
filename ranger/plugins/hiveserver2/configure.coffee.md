
# Ranger HIVE Plugin Configure
Ranger Hive plugin runs inside Hiveserver2's JVM


    module.exports = ->
      hive_ctxs = @contexts 'ryba/hive/server2'
      [ranger_admin_ctx] = @contexts 'ryba/ranger/admin'
      return unless ranger_admin_ctx?
      {ryba} = @config
      {realm, ssl, core_site, hdfs, hadoop_group, hadoop_conf_dir} = ryba
      ranger = ranger_admin_ctx.config.ryba.ranger ?= {}
      ranger.plugins.hive_enabled ?= if hive_ctxs.length > 0 then true else false
      if ranger.plugins.hive_enabled
        throw Error 'Need Hive Server2 to enable ranger Hive Plugin' unless hive_ctxs.length > 0
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
        port = if @config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
        then @config.ryba.hive.server2.site['hive.server2.thrift.http.port']
        else @config.ryba.hive.server2.site['hive.server2.thrift.port']
        httpPath = @config.ryba.hive.server2.site['hive.server2.thrift.http.path']
        hive_url = 'jdbc:hive2://'
        hive_url += "#{@config.host}:#{port}/"
        hive_url += ";principal=#{@config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal']}" if @config.ryba.security is 'kerberos'
        if @config.ryba.hive.server2.site['hive.server2.use.SSL'] is 'true'
          hive_url += ";ssl=true"
          hive_url += ";sslTrustStore=#{@config.ryba.ssl_client['ssl.client.truststore.location']}"
          hive_url += ";trustStorePassword=#{@config.ryba.ssl_client['ssl.client.truststore.password']}"
        if @config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
          hive_url += ";transportMode=#{@config.ryba.hive.server2.site['hive.server2.transport.mode']}"
          hive_url += ";httpPath=#{httpPath}"
        # Commun Configuration
        @config.ryba.ranger ?= {}
        @config.ryba.ranger.user ?= ranger.user
        @config.ryba.ranger.group ?= ranger.group
        @config.ryba.hive.server2.site['hive.security.authorization.manager'] = 'org.apache.ranger.authorization.hive.authorizer.RangerHiveAuthorizerFactory'
        @config.ryba.hive.warehouse_mode = '0000'
        @config.ryba.hive.server2.site['hive.security.authenticator.manager'] = 'org.apache.hadoop.hive.ql.security.SessionStateUserAuthenticator'
        @config.ryba.hive.server2.opts ?= ''
        @config.ryba.hive.server2.opts += " -Djavax.net.ssl.trustStore=#{@config.ryba.ssl_client['ssl.client.truststore.location']} "
        @config.ryba.hive.server2.opts += " -Djavax.net.ssl.trustStorePassword=#{@config.ryba.ssl_client['ssl.server.truststore.password']}"
        # HIVE Plugin configuration
        hive_plugin = @config.ryba.ranger.hive_plugin ?= {}
        hive_plugin.principal ?= ranger.plugins.principal
        hive_plugin.password ?= ranger.plugins.password
        hive_plugin.install ?= {}
        hive_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
        # Should Hive GRANT/REVOKE update XA policies?
        hive_plugin.install['UPDATE_XAPOLICIES_ON_GRANT_REVOKE'] ?= 'true'
        hive_plugin.install['CUSTOM_USER'] ?= "#{@config.ryba.hive.user.name}"
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
            'policy.download.auth.users': "#{@config.ryba.hive.user.name}" #from ranger 0.6
            'tag.download.auth.users': "#{@config.ryba.hive.user.name}"

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
        hive_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{@config.ryba.hive.server2.log_dir}/audit/hdfs/spool"

### HIVE Audit (database storage)

        #Deprecated
        hive_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
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
        else
            hive_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
            hive_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
            hive_plugin.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
            hive_plugin.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

### HIVE Audit (to SOLR)

        if ranger.admin.install['audit_store'] is 'solr'
          hive_plugin.audit ?= {}
          hive_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
          hive_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
          hive_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
          hive_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
          hive_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
          hive_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
          hive_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{@config.ryba.hive.server2.log_dir}/audit/solr/spool"
          hive_plugin.audit['xasecure.audit.destination.solr.force.use.inmemory.jaas.config'] ?= 'true'
          hive_plugin.audit['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
          hive_plugin.audit['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
          hive_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
          hive_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
          hive_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
          hive_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
          hive_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
          hive_princ = @config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal'].replace '_HOST', @config.host
          hive_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.principal'] ?= hive_princ
          hive_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= @config.ryba.hive.server2.site['hive.server2.authentication.kerberos.keytab']

### HIVE Plugin SSL
Used only if SSL is enabled between Policy Admin Tool and Plugin

        if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
          hive_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= @config.ryba.ssl_server['ssl.server.keystore.location']
          hive_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= @config.ryba.ssl_server['ssl.server.keystore.password']
          hive_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= @config.ryba.ssl_client['ssl.client.truststore.location']
          hive_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= @config.ryba.ssl_client['ssl.client.truststore.password']

## Merge hive_plugin conf to ranger admin

        ranger_admin_ctx.config.ryba.ranger.hive_plugin = merge hive_plugin

## Dependencies

    {merge} = require 'mecano/lib/misc'
