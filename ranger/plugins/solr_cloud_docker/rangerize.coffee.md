
# Rangerize Solr Cluster
The configuration slightly differs for Solr in camparison to the other ranger plugins.
The need is to configure the differents solr clusters which are configured by Ryba
As a consequence, the configuration is hold in the `ryba.ranger.solr_plugins` property and
contains as the key the cluster name and configuration the `solr_plugin` config.

This modules injects installation actions in the `ryba/solr/cloud_docker` contexts.
As a consequence, `ryba/ranger/admin` and `ryba/solr/cloud_docker` must not be installed on
the same machine.

    module.exports = (context, name, cluster_config, host_config) ->
      [ranger_admin_ctx] = context.contexts 'ryba/ranger/admin'
      ranger = ranger_admin_ctx.config.ryba.ranger ?= {}
      ryba = context.config.ryba
      {solr, core_site} = context.config.ryba
      # Solr Plugin(s) configuration
      solr_plugin = host_config.solr_plugin ?= {}
      solr_plugin.ranger_user ?=
        "name": 'solr'
        "firstName": 'solr'
        "lastName": 'hadoop'
        "emailAddress": 'solr@hadoop.ryba'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1
      solr_plugin.principal ?= solr.admin_principal
      solr_plugin.password ?= solr.admin_password
      solr_plugin.install ?= {}
      solr_plugin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
      solr_plugin.install['CUSTOM_USER'] ?= "#{solr.user.name}"
      solr_plugin.install['CUSTOM_GROUP'] ?= "#{solr.group.name}"

### Solr Policy Admin Tool
This plugin configuration change from the other plugin.
It aims to be used on its own by `ryba/solr/cloud_docker` module.
For each `solr/cloud_docker` present in the configuration  a repo is created on
the ranger webui, except for the `solr/cloud_docker` cluster used for Ranger audit logs.

This module, configure the `ryba/solr/cloud_docker` nodes. The steps are:
- Installation of the official ranger-solr-plugin.
- Configuring installation scripts for each cluster to target conf directory
and library.
- Posting the corresponding repo to to ranger-admin.

      solr_plugin.install['POLICY_MGR_URL'] ?= ranger.admin.install['policymgr_external_url']
      solr_plugin.install['REPOSITORY_NAME'] ?= name
      solr_urls = cluster_config.hosts.map( (host) ->
       "#{if cluster_config.is_ssl_enabled  then 'https://' else 'http://'}#{host}:#{cluster_config.port}").join(',')
      solr_plugin.service_repo ?=  
        'description': "Ranger plugin Repo for:#{name}"
        'isEnabled': true
        'name': solr_plugin.install['REPOSITORY_NAME']
        'type': 'solr'
        'configs':
          'solr.url': solr_urls
          'policy.download.auth.users': "#{solr.user.name}" #from ranger 0.6
          'tag.download.auth.users': "#{solr.user.name}"
      if cluster_config.authentication_class isnt 'org.apache.solr.security.KerberosPlugin'
      then throw Error 'Ranger Solr Plugin does only support Kerberized solr cluster'
      solr_plugin.service_repo['configs']['username'] ?= cluster_config.admin_principal
      solr_plugin.service_repo['configs']['password'] ?= cluster_config.admin_password

### Solr Plugin audit

      solr_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if solr_plugin.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        solr_plugin.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/#{name}/%app-type%/%time:yyyyMMdd%"
        solr_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= "#{cluster_config.log_dir}/ranger/%app-type%/audit"
        solr_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= "#{cluster_config.log_dir}/ranger/%app-type%/archive"
        solr_plugin.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
        solr_plugin.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
        solr_plugin.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
        solr_plugin.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
        solr_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
        solr_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
        solr_plugin.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
        solr_plugin.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

### Solr Audit (HDFS Storage)

      solr_plugin.install['XAAUDIT.SUMMARY.ENABLE'] ?= 'true'
      # AUDIT TO HDFS
      solr_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
      solr_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit/#{name}/"
      solr_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{cluster_config.log_dir}/audit/hdfs/spool"

### Solr Audit (database storage)

      #Deprecated
      solr_plugin.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
      if solr_plugin.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
        solr_plugin.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
        switch solr_plugin.install['XAAUDIT.DB.FLAVOUR']
          when 'MYSQL'
            solr_plugin.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
            solr_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= ranger.admin.install['db_host']
            solr_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= ranger.admin.install['audit_db_name']
            solr_plugin.install['XAAUDIT.DB.USER_NAME'] ?= ranger.admin.install['audit_db_user']
            solr_plugin.install['XAAUDIT.DB.PASSWORD'] ?= ranger.admin.install['audit_db_password']
          when 'ORACLE'
            throw Error 'Ryba does not support ORACLE Based Ranger Installation'
          else
            throw Error "Apache Ranger does not support chosen DB FLAVOUR"
      else
        solr_plugin.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
        solr_plugin.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
        solr_plugin.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
        solr_plugin.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

### Solr Audit (to SOLR)
Note, when using `ryba/solr/cloud_docker` with version > 6.0.0, the ranger-solr-plugin
doest not work properly, because the plugin load 6+ version class when instantiating
its utility class.
Inded until now (hdp 2.5.3.0), ranger plugin is base on HDP' solr version which is
5.5.0

      if ranger.admin.install['audit_store'] is 'solr'
        solr_plugin.audit ?= {}
        solr_plugin.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'false'
        solr_plugin.install['XAAUDIT.SOLR.ENABLE'] ?= 'false'
        solr_plugin.install['XAAUDIT.SOLR.URL'] ?= ranger.admin.install['audit_solr_urls']
        solr_plugin.install['XAAUDIT.SOLR.USER'] ?= ranger.admin.install['audit_solr_user']
        solr_plugin.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= ranger.admin.install['audit_solr_zookeepers']
        solr_plugin.install['XAAUDIT.SOLR.PASSWORD'] ?= ranger.admin.install['audit_solr_password']
        solr_plugin.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{cluster_config.log_dir}/ranger/audit/solr/spool"
        solr_plugin.audit['xasecure.audit.destination.solr.force.use.inmemory.jaas.config'] ?= 'true'
        solr_plugin.audit['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
        solr_plugin.audit['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
        solr_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
        solr_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
        solr_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
        solr_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
        solr_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
        solr_princ = host_config.auth_opts['solr.kerberos.principal'].replace '_HOST', host_config.host
        solr_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.principal'] ?= solr_princ
        solr_plugin.audit['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= host_config.auth_opts['solr.kerberos.keytab']

### Solr Plugin SSL
Used only if SSL is enabled between Policy Admin Tool and Plugin

      if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        solr_plugin.install['SSL_KEYSTORE_FILE_PATH'] ?= context.config.ryba.ssl_server['ssl.server.keystore.location']
        solr_plugin.install['SSL_KEYSTORE_PASSWORD'] ?= context.config.ryba.ssl_server['ssl.server.keystore.password']
        solr_plugin.install['SSL_TRUSTSTORE_FILE_PATH'] ?= context.config.ryba.ssl_client['ssl.client.truststore.location']
        solr_plugin.install['SSL_TRUSTSTORE_PASSWORD'] ?= context.config.ryba.ssl_client['ssl.client.truststore.password']

## Docker Specific Configuration
The ranger-solr-plugin is installed on the host machine, and mounted by containers
which does need it.

      solr_plugin.install['COMPONENT_INSTALL_DIR_NAME'] ?= "#{solr.cloud_docker.conf_dir}/clusters/#{name}/server"
      context.before
        type: ['file','yaml']
        target: "#{solr.cloud_docker.conf_dir}/clusters/#{name}/docker-compose.yml"
        handler: (_, callback) ->
          solr_plugin.hdp_current_version = null
          context.system.execute
            cmd:  "hdp-select versions | tail -1"
            header: 'configure mounts'
          , (err, executed, stdout, stderr) ->
            return callback err if err
            solr_plugin.hdp_current_version = stdout.trim() if executed
            mounts = [
              "/etc/ranger/#{solr_plugin.install['REPOSITORY_NAME']}:/etc/ranger/#{solr_plugin.install['REPOSITORY_NAME']}"
              '/etc/hadoop/conf:/etc/hadoop/conf'
              "#{cluster_config.conf_dir}/server/solr-webapp/webapp/WEB-INF/classes:/usr/solr-cloud/current/server/solr-webapp/webapp/WEB-INF/classes"
              "/usr/hdp/#{solr_plugin.hdp_current_version}/ranger-solr-plugin:/usr/hdp/#{solr_plugin.hdp_current_version}/ranger-solr-plugin"
            ]
            for name, service of cluster_config.service_def
              for mount in mounts
                service.volumes.push mount unless service.volumes.indexOf(mount) isnt -1
          context.call 'ryba/ranger/plugins/solr_cloud_docker/install', solr_cluster: {config: cluster_config, name: name, host_config: host_config}
          context.then callback

## Merge solr_plugin conf to ranger admin

      ranger_admin_ctx.config.ryba.ranger.solr_plugins ?= {}
      ranger_admin_ctx.config.ryba.ranger.solr_plugins[name] =  merge solr_plugin

## Dependencies

    {merge} = require 'nikita/lib/misc'
