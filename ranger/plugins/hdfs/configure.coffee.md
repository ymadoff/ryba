
# Ranger HDFS Plugin Configure

For the HDFS plugin, the executed script already create the hdfs user to ranger admin
as external.
    
    module.exports = ->
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      dn_ctxs = @contexts 'ryba/hadoop/hdfs_dn'
      [ranger_admin_ctx] = @contexts 'ryba/ranger/admin'
      return unless ranger_admin_ctx?
      {ryba} = @config
      {realm, ssl, core_site, hdfs, hadoop_group, hadoop_conf_dir} = ryba
      ranger = ranger_admin_ctx.config.ryba.ranger ?= {}
      ranger.plugins.hdfs_enabled ?= if nn_ctxs.length > 0 then true else false
      ranger.plugins.hdfs_configured ?= false
      if ranger.plugins.hdfs_enabled and not ranger.plugins.hdfs_configured
        throw Error 'Need HDFS to enable ranger HDFS Plugin' unless nn_ctxs.length > 0
        # for nn_ctx in nn_ctxs
          # Commun Configuration
        @config.ryba.hdfs.nn.site['dfs.namenode.inode.attributes.provider.class'] ?= 'org.apache.ranger.authorization.hadoop.RangerHdfsAuthorizer'
        @config.ryba.ranger ?= {}
        @config.ryba.ranger.user = ranger.user
        @config.ryba.ranger.group = ranger.group
        @config.ryba.hdfs.namenode_opts ?= ''
        @config.ryba.hdfs.namenode_opts += " -Djavax.net.ssl.trustStore=#{@config.ryba.hdfs.nn.conf_dir}/truststore "
        @config.ryba.hdfs.namenode_opts += " -Djavax.net.ssl.trustStorePassword=#{@config.ryba.ssl_server['ssl.server.truststore.password']}"
        # HDFS Plugin configuration
        hdfs_plugin = @config.ryba.ranger.hdfs_plugin ?= {}
        ranger_admin_ctx.config.ryba.ranger.hdfs_plugin = hdfs_plugin
        hdfs_plugin.install ?= {}
        hdfs_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

### HDFS Plugin Policy Admin Tool
The repository name should match the reposity name in web ui.
The properties can be found [here][hdfs-repository]

        hdfs_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
        hdfs_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hdfs'
        hdfs_plugin.service_repo ?=
          'configs': 
            'password': hdfs.krb5_user.password
            'username': hdfs.krb5_user.principal
            'fs.default.name': core_site['fs.defaultFS']
            'hadoop.security.authentication': core_site['hadoop.security.authentication']
            'dfs.namenode.kerberos.principal': nn_ctxs[0].config.ryba.hdfs.nn.site['dfs.namenode.kerberos.principal']
            'dfs.datanode.kerberos.principal': dn_ctxs[0].config.ryba.hdfs.site['dfs.datanode.kerberos.principal']
            'hadoop.rpc.protection': core_site['hadoop.rpc.protection']
            'hadoop.security.authorization': core_site['hadoop.security.authorization']
            'hadoop.security.auth_to_local': core_site['hadoop.security.auth_to_local']   
            'commonNameForCertificate': ''
            'policy.download.auth.users': "#{nn_ctxs[0].config.ryba.hdfs.user.name}" #from ranger 0.6
            'tag.download.auth.users': "#{nn_ctxs[0].config.ryba.hdfs.user.name}"
          'description': 'HDFS Repo'
          'isEnabled': true
          'name': hdfs_plugin.install['REPOSITORY_NAME']
          'type': 'hdfs'

### HDFS Plugin Audit (database storage)

        #Deprecated
        hdfs_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
        hdfs_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
        if hdfs_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
          hdfs_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
          switch hdfs_plugin.install['XAAUDIT.DB.FLAVOUR']
            when 'MYSQL'
              hdfs_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
              hdfs_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
              hdfs_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
              hdfs_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
            when 'ORACLE'
              throw Error 'Ryba does not support ORACLE Based Ranger Installation'
            else
              throw Error "Apache Ranger does not support chosen DB FLAVOUR"
        else
            # This properties are needed even if they are not user
            # We set it to NONE to let the script execute
            hdfs_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
            hdfs_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
            hdfs_plugin.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
            hdfs_plugin.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

### HDFS Plugin Audit (HDFS Storage)
Configure Audit to HDFS

        hdfs_plugin.audit ?= {}
        # V3 configuration
        hdfs_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        hdfs_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
        hdfs_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{@config.ryba.hdfs.log_dir}/audit/hdfs/spool"
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
          hdfs_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{@config.ryba.hdfs.log_dir}/audit/solr/spool"
          hdfs_plugin.audit['xasecure.audit.destination.solr.force.use.inmemory.jaas.config'] ?= 'true'
          hdfs_plugin.audit['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
          hdfs_plugin.audit['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
          hdfs_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
          hdfs_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
          hdfs_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
          hdfs_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
          hdfs_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
          hdfs_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= @config.ryba.hdfs.nn.site['dfs.namenode.keytab.file']
          nn_princ = @config.ryba.hdfs.nn.site['dfs.namenode.kerberos.principal'].replace '_HOST', @config.host
          hdfs_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.principal'] ?= nn_princ

### HDFS Plugin SSL

        if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
          hdfs_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= "#{@config.ryba.hdfs.nn.conf_dir}/keystore"
          hdfs_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= @config.ryba.hdfs.nn.ssl_server['ssl.server.keystore.password']
          hdfs_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= "#{@config.ryba.hdfs.nn.conf_dir}/truststore"
          hdfs_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= @config.ryba.hdfs.nn.ssl_server['ssl.server.truststore.password']
