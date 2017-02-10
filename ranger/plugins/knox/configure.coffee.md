
## Ranger Knox Plugin Configure

    module.exports = ->
      knox_ctxs = @contexts 'ryba/knox'
      [ranger_admin_ctx] = @contexts 'ryba/ranger/admin'
      return unless ranger_admin_ctx?
      {ryba} = @config
      {realm, ssl, core_site, hdfs, hadoop_group, hadoop_conf_dir} = ryba
      ranger = ranger_admin_ctx.config.ryba.ranger ?= {}
      ranger.plugins.knox_enabled ?= if knox_ctxs.length > 0 then true else false
      if ranger.plugins.knox_enabled
        throw Error 'Need at least one Knox Server to enable ranger Knox Plugin' unless knox_ctxs.length > 0
        ranger.users['knox'] ?=
          "name": 'knox'
          "firstName": 'knox'
          "lastName": 'hadoop'
          "emailAddress": 'knox@hadoop.ryba'
          'userSource': 1
          'userRoleList': ['ROLE_USER']
          'groups': []
          'status': 1
        # Commun Configuration
        @config.ryba.ranger ?= {}
        @config.ryba.ranger.user = ranger.user
        @config.ryba.ranger.group = ranger.group
        # Knox Plugin configuration
        knox_plugin = @config.ryba.ranger.knox_plugin ?= {}
        knox_plugin.install ?= {}
        knox_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
        knox_plugin.install['CUSTOM_USER'] ?= "#{@config.ryba.knox.user.name}"
        knox_plugin.install['KNOX_HOME'] ?= '/usr/hdp/current/knox-server'

## Knox Ranger Plugin Tool
The repository name should match the reposity name in web ui.
The properties can be found [here][hdfs-repository]

        knox_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
        knox_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-knox'
        {knox} = @config.ryba
        knox_protocol = if knox.ssl? then 'https' else 'http'
        knox_url = "#{knox_protocol}://#{@config.host}"
        knox_url += ":#{knox.site['gateway.port']}/#{knox.site['gateway.path']}"
        knox_url += '/admin/api/v1/topologies'
        knox_plugin.service_repo ?=
          'configs':
            'password': hdfs.krb5_user.password
            'username': hdfs.krb5_user.principal
            'knox.url': "#{knox_url}"
            'commonNameForCertificate': ''
            'policy.download.auth.users': "#{@config.ryba.knox.user.name}" #from ranger 0.6
            'tag.download.auth.users': "#{@config.ryba.knox.user.name}"
          'description': 'Knox Repo'
          'isEnabled': true
          'name': knox_plugin.install['REPOSITORY_NAME']
          'type': 'knox'

## KNOX Plugin Audit (database storage)

        #Deprecated
        knox_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
        knox_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
        if knox_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
          knox_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
          switch knox_plugin.install['XAAUDIT.DB.FLAVOUR']
            when 'MYSQL'
              knox_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
              knox_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
              knox_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
              knox_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
            when 'ORACLE'
              throw Error 'Ryba does not support ORACLE Based Ranger Installation'
            else
              throw Error "Apache Ranger does not support chosen DB FLAVOUR"
        else
            knox_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
            knox_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
            knox_plugin.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
            knox_plugin.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

## Knox Gateway Plugin Audit (HDFS Storage)
Configure Audit to HDFS

        knox_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        knox_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
        knox_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/knox/audit/hdfs/spool'
        knox_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
        if knox_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
          knox_plugin.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/%app-type%/%time:yyyyMMdd%"
          knox_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= '/var/log/ranger/%app-type%/audit'
          knox_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= '/var/log/ranger/%app-type%/archive'
          knox_plugin.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
          knox_plugin.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
          knox_plugin.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
          knox_plugin.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
          knox_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
          knox_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
          knox_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
          knox_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

## Knox Plugin Audit (SOLR Storage)
Configure Audit to SOLR

        if ranger.admin.install['audit_store'] is 'solr'
          knox_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
          knox_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
          knox_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
          knox_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
          knox_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
          knox_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
          knox_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/knox/audit/solr/spool'

## Knox Plugin SSL

        if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
          knox_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= @config.ryba.ssl_server['ssl.server.keystore.location']
          knox_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= @config.ryba.ssl_server['ssl.server.keystore.password']
          knox_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= @config.ryba.ssl_server['ssl.server.truststore.location']
          knox_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= @config.ryba.ssl_server['ssl.server.truststore.password']

## Merge knox_plugin conf to ranger admin

        ranger_admin_ctx.config.ryba.ranger.knox_plugin = merge knox_plugin

## Dependencies

    {merge} = require 'mecano/lib/misc'
