
## Ranger HBase Plugin Configure

    module.exports = ->
      hm_ctxs = @contexts 'ryba/hbase/master'
      rs_ctxs = @contexts 'ryba/hbase/regionserver'
      [ranger_admin_ctx] = @contexts 'ryba/ranger/admin'
      return unless ranger_admin_ctx?
      {ryba} = @config
      {realm, ssl, core_site, hdfs, hadoop_group, hadoop_conf_dir} = ryba
      ranger = ranger_admin_ctx.config.ryba.ranger ?= {}
      ranger.plugins.hbase_enabled ?= if hm_ctxs.length > 0 then true else false
      type = if @config.ryba.hbase_plugin_is_master then 'master' else 'rs'
      log_dir = @config.ryba.hbase["#{type}"].log_dir
      conf_dir = @config.ryba.hbase["#{type}"].conf_dir
      if ranger.plugins.hbase_enabled
        throw Error 'Need HBase to enable ranger HBase Plugin' unless hm_ctxs.length > 0
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
        # Commun Configuration
        @config.ryba.ranger ?= {}
        @config.ryba.ranger.user = @config.ryba.ranger.user
        @config.ryba.ranger.group = @config.ryba.ranger.group
        # HBase Plugin configuration
        hbase_plugin = @config.ryba.ranger.hbase_plugin ?= {}
        hbase_plugin.policy_name ?= "Ranger-Ryba-HBase-Policy"
        hbase_plugin.install ?= {}
        hbase_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
        hbase_plugin.install['CUSTOM_USER'] ?= "#{@config.ryba.hbase.user.name}"

### HBase regionserver env
Some ranger plugins needs to have the configuration file on thei classpath to make 
configuration separation complete.

        #fix ranger hbase rs plugin
        for ctx in rs_ctxs
          ctx.config.ryba ?= {}
          ctx.config.ryba.hbase ?= {}
          ctx.config.ryba.hbase.rs ?= {}
          ctx.config.ryba.hbase.rs.env ?= {}
          if not ctx.config.ryba?.hbase?.rs?.env['HBASE_CLASSPATH']?
            ctx.config.ryba.hbase.rs.env['HBASE_CLASSPATH'] = "$HBASE_CLASSPATH:/etc/hbase-regionserver/conf/core-site.xml"
          else if (ctx.config.ryba.hbase.rs.env['HBASE_CLASSPATH'].indexOf(":/etc/hbase-regionserver/conf/core-site.xml") is -1)
            ctx.config.ryba.hbase.rs.env['HBASE_CLASSPATH'] += ":/etc/hbase-regionserver/conf/core-site.xml"

### HBase Policy Admin Tool
The repository name should match the reposity name in web ui.

        hbase_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
        hbase_plugin.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hbase'
        hbase_plugin.service_repo ?=
          'configs': 
            'username': @config.ryba.hbase.admin.principal
            'password': @config.ryba.hbase.admin.password
            'hadoop.security.authorization': core_site['hadoop.security.authorization']
            'hbase.master.kerberos.principal': @config.ryba.hbase["#{type}"].site['hbase.master.kerberos.principal']
            'hadoop.security.authentication': core_site['hadoop.security.authentication']
            'hbase.security.authentication': @config.ryba.hbase["#{type}"].site['hbase.security.authentication']
            'hbase.zookeeper.property.clientPort': @config.ryba.hbase["#{type}"].site['hbase.zookeeper.property.clientPort']
            'hbase.zookeeper.quorum': @config.ryba.hbase["#{type}"].site['hbase.zookeeper.quorum']
            'zookeeper.znode.parent': @config.ryba.hbase["#{type}"].site['zookeeper.znode.parent']
            'policy.download.auth.users': "#{@config.ryba.hbase.user.name}" #from ranger 0.6
            'tag.download.auth.users': "#{@config.ryba.hbase.user.name}"
            'policy.grantrevoke.auth.users': "#{@config.ryba.hbase.user.name}"
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
        hbase_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{log_dir}/audit/hdfs/spool"

### HBase Audit (database storage)

        #Deprecated
        hbase_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
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
        else
            hbase_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
            hbase_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
            hbase_plugin.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
            hbase_plugin.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'


### HBase Audit (to SOLR)

        if ranger.admin.install['audit_store'] is 'solr'
          hbase_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
          hbase_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
          hbase_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
          hbase_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
          hbase_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
          hbase_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
          hbase_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{log_dir}/audit/solr/spool"

### HBase Plugin Execution

      if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        @config.ryba.ranger.hbase_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= @config.ryba.ssl_server['ssl.server.keystore.location']
        @config.ryba.ranger.hbase_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= @config.ryba.ssl_server['ssl.server.keystore.password']
        @config.ryba.ranger.hbase_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= @config.ryba.ssl_client['ssl.client.truststore.location']
        @config.ryba.ranger.hbase_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= @config.ryba.ssl_client['ssl.client.truststore.password']

## Merge hive_plugin conf to ranger admin

        ranger_admin_ctx.config.ryba.ranger.hbase_plugin = merge hbase_plugin

## Dependencies

    {merge} = require 'mecano/lib/misc'
