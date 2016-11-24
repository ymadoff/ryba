
# Ranger Knox Plugin Configure

    module.exports = ->
      kb_ctxs = @contexts 'ryba/kafka/broker'
      [ranger_admin_ctx] = @contexts 'ryba/ranger/admin'
      return unless ranger_admin_ctx?
      {ryba} = @config
      {realm, ssl, core_site, hdfs, hadoop_group, hadoop_conf_dir} = ryba
      ranger = ranger_admin_ctx.config.ryba.ranger ?= {}

      #de-activating now 
      #https://mail-archives.apache.org/mod_mbox/incubator-ranger-user/201605.mbox/%3C363AE5BD-D796-425B-89C9-D481F6E74BAF@apache.org%3E
      ranger.plugins.kafka_enabled ?= if kb_ctxs.length > 0 then true else false
      if ranger.plugins.kafka_enabled
        throw Error 'Need at least one kafka broker to enable ranger kafka Plugin' unless kb_ctxs.length > 0
        # Commun Configuration
        @config.ryba.ranger ?= {}
        @config.ryba.ranger.user = ranger.user
        @config.ryba.ranger.group = ranger.group
        # HDFS Plugin configuration
        kafka_plugin = @config.ryba.ranger.kafka_plugin ?= {}
        @config.ryba.kafka.broker.config['authorizer.class.name'] = 'org.apache.ranger.authorization.kafka.authorizer.RangerKafkaAuthorizer'
        ranger.users["#{@config.ryba.kafka.user.name}"] ?=
          name: "#{@config.ryba.kafka.user.name}"
          firstName: ''
          lastName: ''
          emailAddress: ''
          userSource: 1
          userRoleList: ['ROLE_USER']
          groups: []
          status: 1
        protocols = @config.ryba.kafka.broker.protocols
        if (protocols.indexOf('PLAINTEXT') isnt -1) or (protocols.indexOf('SSL') isnt -1)
          ranger.users['ANONYMOUS'] ?=
            name: "ANONYMOUS"
            firstName: ''
            lastName: ''
            emailAddress: ''
            userSource: 1
            userRoleList: ['ROLE_USER']
            groups: []
            status: 1
        kafka_plugin.install ?= {}
        kafka_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
        kafka_plugin.install['CUSTOM_USER'] ?= "#{@config.ryba.kafka.user.name}"
        kafka_plugin.install['XAAUDIT.SUMMARY.ENABLE'] ?= 'true'

## Kafka Policy Admin Tool
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
            'policy.download.auth.users': "#{kb_ctxs[0].config.ryba.kafka.user.name}" #from ranger 0.6
            'commonNameForCertificate': ''           
          'description': 'kafka Repository'
          'isEnabled': true
          'name': kafka_plugin.install['REPOSITORY_NAME']
          'type': 'kafka'

## Kafka Audit (database storage)

        #Deprecated
        kafka_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
        kafka_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
        if kafka_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
          kafka_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
          switch kafka_plugin.install['XAAUDIT.DB.FLAVOUR']
            when 'MYSQL'
              kafka_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
              kafka_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
              kafka_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
              kafka_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
            when 'ORACLE'
              throw Error 'Ryba does not support ORACLE Based Ranger Installation'
            else
              throw Error "Apache Ranger does not support chosen DB FLAVOUR"
        else
            kafka_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
            kafka_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
            kafka_plugin.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
            kafka_plugin.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

## Kafka Audit (HDFS Storage)

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

## Kafka Audit (to SOLR)

        if ranger.admin.install['audit_store'] is 'solr'
          kafka_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
          kafka_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
          kafka_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
          kafka_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
          kafka_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
          kafka_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
          kafka_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= '/var/log/hadoop/kafka/audit/solr/spool'

## Kafka Plugin SSL

        if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
          kafka_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= @config.ryba.ssl_server['ssl.server.keystore.location']
          kafka_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= @config.ryba.ssl_server['ssl.server.keystore.password']
          kafka_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= @config.ryba.ssl_client['ssl.client.truststore.location']
          kafka_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= @config.ryba.ssl_client['ssl.client.truststore.password']
