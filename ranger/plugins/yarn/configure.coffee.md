
## Ranger YARN Plugin

## Configure
This modules configures every hadoop plugin needed to enable Ranger. It configures
variables but also inject some function to be executed.

    module.exports = ->
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'
      [ranger_admin_ctx] = @contexts 'ryba/ranger/admin'
      return unless ranger_admin_ctx?
      {ryba} = @config
      {realm, ssl, core_site, hdfs, hadoop_group, hadoop_conf_dir} = ryba
      ranger = ranger_admin_ctx.config.ryba.ranger ?= {}
      ranger.plugins.yarn_enabled ?= if rm_ctxs.length > 0 then true else false
      log_dir = if @config.ryba.yarn_plugin_is_master 
      then @config.ryba.yarn.rm.log_dir 
      else @config.ryba.yarn.nm.log_dir
      if ranger.plugins.yarn_enabled 
        throw Error 'Need YARN to enable ranger YARN Plugin' unless rm_ctxs.length > 0
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
          # Commun Configuration
        @config.ryba.ranger ?= {}
        @config.ryba.ranger.user ?= ranger.user
        @config.ryba.ranger.group ?= ranger.group
        # YARN Plugin configuration
        yarn_plugin = @config.ryba.ranger.yarn_plugin ?= {}
        yarn_plugin.principal ?= ranger.plugins.principal
        yarn_plugin.password ?= ranger.plugins.password        
        yarn_plugin.install ?= {}
        yarn_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

## YARN Policy Admin Tool
The repository name should match the reposity name in web ui.

        yarn_url = if rm_ctxs[0].config.ryba.yarn.rm.site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{rm_ctxs[0].config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.http.address.#{rm_ctxs[0].config.shortname}"]}"
        else "https://#{rm_ctxs[0].config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.https.address.#{rm_ctxs[0].config.shortname}"]}"
        yarn_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
        yarn_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-yarn'
        yarn_plugin.service_repo ?=
          'configs': 
            'password': hdfs.krb5_user.password
            'username': hdfs.krb5_user.principal
            'yarn.url': yarn_url
            'policy.download.auth.users': "#{rm_ctxs[0].config.ryba.yarn.user.name}" #from ranger 0.6
            'tag.download.auth.users': "#{rm_ctxs[0].config.ryba.yarn.user.name}"
          'description': 'YARN Repo'
          'isEnabled': true
          'name': yarn_plugin.install['REPOSITORY_NAME']
          'type': 'yarn'

## YARN Plugin Audit (to HDFS)

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

        # AUDIT TO HDFS
        yarn_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        yarn_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
        yarn_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{log_dir}/audit/hdfs/spool"

## YARN Audit (database storage)

        #Deprecated
        yarn_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
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
        else
            yarn_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
            yarn_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
            yarn_plugin.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
            yarn_plugin.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

## YARN Audit (to SOLR)

        if ranger.admin.install['audit_store'] is 'solr'
          yarn_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
          yarn_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
          yarn_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
          yarn_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
          yarn_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
          yarn_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
          yarn_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{log_dir}/audit/solr/spool"

## Plugin SSL
SSL can be configured to use SSL if ranger admin has SSL enabled.
        
        if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
          @config.ryba.ranger.yarn_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= @config.ryba.ssl_server['ssl.server.keystore.location']
          @config.ryba.ranger.yarn_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= @config.ryba.ssl_server['ssl.server.keystore.password']
          @config.ryba.ranger.yarn_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= @config.ryba.ssl_client['ssl.client.truststore.location']
          @config.ryba.ranger.yarn_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= @config.ryba.ssl_client['ssl.client.truststore.password']
