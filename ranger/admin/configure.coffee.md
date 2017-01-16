
## Configure
This modules configures every hadoop plugin needed to enable Ranger. It configures
variables but also inject some function to be executed.

    module.exports = ->
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      dn_ctxs = @contexts 'ryba/hadoop/hdfs_dn'
      nm_ctxs = @contexts 'ryba/hadoop/yarn_nm'
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'
      hm_ctxs = @contexts 'ryba/hbase/master'
      rs_ctxs = @contexts 'ryba/hbase/regionserver'
      hbcli_ctxs = @contexts 'ryba/hbase/client'
      kb_ctxs = @contexts 'ryba/kafka/broker'
      sc_ctxs = @contexts 'ryba/solr/cloud'
      st_ctxs = @contexts 'ryba/solr/standalone'
      scd_ctxs = @contexts 'ryba/solr/cloud_docker'
      hive_ctxs = @contexts 'ryba/hive/server2'
      knox_ctxs = @contexts 'ryba/knox'
      {ryba} = @config
      {realm, db_admin, ssl, core_site, hdfs, hadoop_group, hadoop_conf_dir} = ryba
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
      ranger.user.groups ?= 'hadoop'
      ranger.admin ?= {}
      ranger.admin.conf_dir ?= '/etc/ranger/admin/conf'
      ranger.admin.pid_dir ?= '/var/run/ranger/admin'
      ranger.admin.log_dir ?= '/var/log/ranger/admin'

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
      ranger.admin.conf_dir ?= '/etc/ranger/admin'
      ranger.admin.site ?= {}
      ranger.admin.site ?= {}
      ranger.admin.site['ranger.service.http.port'] ?= '6080'
      ranger.admin.site['ranger.service.https.port'] ?= '6182'
      ranger.admin.install ?= {}
      ranger.admin.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
      # Needed starting from 2.5 version to not have problem during setup execution
      ranger.admin.install['hadoop_conf'] ?= "#{hadoop_conf_dir}"
      ranger.admin.install['RANGER_ADMIN_LOG_DIR'] ?= "#{ranger.admin.log_dir}"

# Kerberos
[Starting from 2.5][ranger-upgrade-24-25], Ranger supports Kerberos Authentication for secured cluster

      if @config.ryba.security is 'kerberos'
        ranger.admin.install['spnego_principal'] ?= "HTTP/#{@config.host}@#{realm}"
        ranger.admin.install['spnego_keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
        ranger.admin.install['token_valid'] ?= '30'
        ranger.admin.install['cookie_domain'] ?= "#{@config.host}"
        ranger.admin.install['cookie_path'] ?= '/'
        ranger.admin.install['admin_principal'] ?= "rangeradmin/#{@config.host}@#{realm}"
        ranger.admin.install['admin_keytab'] ?= '/etc/security/keytabs/ranger.admin.service.keytab'
        ranger.admin.install['lookup_principal'] ?= "rangerlookup/#{@config.host}@#{realm}"
        ranger.admin.install['lookup_keytab'] ?= "/etc/security/keytabs/ranger.lookup.service.keytab"

# Audit Storage
Ranger can store  audit to different storage type.
- HDFS ( Long term and scalable storage)
- SOLR ( short term storage & Ranger WEBUi)
- DB Flavor ( mid term storage & Ranger WEBUi)
We do not advice to use DB Storage as it is not efficient to query when it grows up.
Hortonworks recommandations are to enable SOLR and HDFS Storage.

      ranger.admin.install['audit_store'] ?= 'solr'

## Solr Audit Configuration
Here SOLR configuration is discovered and ranger admin is set up.

Ryba support both Solr Cloud mode and Solr Standalone installation. 

The `ranger.admin.solr_type` designates the type of solr service (ie standalone, cloud, cloud indocker)
used for Ranger.
The type requires differents instructions/configuration for ranger plugin audit to work.
- Solr Standalone `ryba/solr/standalone`
  Ryba default. You need to set `ryba/solr/standalone` on one host.
- Solr Cloud `ryba/solr/cloud`
  Changes  property `ranger.admin.solr_type` to `cloud` and deploy `ryba/solr/cloud`
  module on at least one host.
- Solr Cloud on docker `ryba/solr/cloud_docker`
  Changes  property `ranger.admin.solr_type` to `cloud_docker`.
  Important:
    For this to work you need to deploy `ryba/solr/cloud_docker` module on at least on host.
    AND you also need to setup a solr cluster in your configuration, for ryba being able to configure
      ranger with this cluster. 
    Ryba configures Ranger by using one of the cluster available
    You can configure it by using `config.ryba.solr.cloud_docker.clusters` property.
    Ryba will search by default for an instance named `ranger_cluster` which is set
    by the property `ranger.admin.cluster_name`.
    An example is available in [the ryba-cluster config file][ryba-cluster-conf].
  
Note July 2016:
The previous properties works only with (HDP 2.4) `solr.BasicAuthPlugin` (in solr cluster config).
And it is configured by Ryba only in ryba/solr/cloud_docker installation.

If no `ryba/solr/*` is configured Ranger admin deploys a `ryba/solr/standalone` 
on the same host than `ryba/ranger/admin` module.

      ranger.admin.solr_type ?= 'single'
      solr = {}
      solrs_urls = ''
      solr_ctx = {}
      switch ranger.admin.solr_type
        when 'single'
          throw Error 'No Solr Standalone Server configured' unless st_ctxs.length > 0
          solr_ctx = st_ctxs[0]
          solr = solr_ctx.config.ryba.solr
          ranger.admin.install['audit_solr_port'] ?= ctx.config.ryba.solr.single.port
          ranger.admin.install['audit_solr_zookeepers'] ?= 'NONE'
          solrs_urls = st_ctxs.map( (ctx) -> 
           "#{if solr.single.ssl.enabled  then 'https://'  else 'http://'}#{ctx.config.host}:#{ctx.config.ryba.solr.single.port}")
            .map( (url) -> if ranger.admin.solr_type is 'single' then "#{url}/solr/ranger_audits" else "#{url}")
            .join(',')
          if @params.command is 'install'
            solr_ctx
            .after
              type: 'java_keystore_add'
              keystore: solr["#{ranger.admin.solr_type}"]['ssl_trustore_path']
              storepass: solr["#{ranger.admin.solr_type}"]['ssl_keystore_pwd']
              caname: "hadoop_root_ca"
              handler: -> @call 'ryba/ranger/admin/solr_bootstrap'
          break;
        when 'cloud'
          throw Error 'No Solr Cloud Server configure' unless sc_ctxs.length > 0
          solr_ctx = sc_ctxs[0]
          solr = sc_ctxs[0].config.ryba.solr
          ranger.admin.install['audit_solr_port'] ?= ctx.config.ryba.solr.cloud.port
          solrs_urls = sc_ctxs.map( (ctx) ->
           "#{if solr.cloud.ssl.enabled  then 'https://'  else 'http://'}#{ctx.config.host}:#{ctx.config.ryba.solr.cloud.port}")
            .map( (url) -> if ranger.admin.solr_type is 'single' then "#{url}/solr/ranger_audits" else "#{url}")
            .join(',')
          ranger.admin.install['audit_solr_zookeepers'] ?= solr["#{ranger.admin.solr_type}"]['zkhosts']          
          if @params.command is 'install'
            solr_ctx
            .after
              type: ['service','start']
              name: 'solr'
              handler: -> @call 'ryba/ranger/admin/solr_bootstrap'
          break;
        when 'cloud_docker'
          throw Error 'No Solr Cloud Server configured' unless scd_ctxs.length > 0 or ranger.admin.cluster_name?
          cluster_name = ranger.admin.cluster_name ?= 'ranger_cluster'
          ranger.admin.solr_admin_user ?= 'solr'
          ranger.admin.solr_admin_password ?= 'SolrRocks' #Default
          ranger.admin.solr_users ?= [
            name: 'ranger'
            secret: 'ranger123'
          ]
          # Get Solr Method Configuration
          solr_clusterize = require '../../solr/cloud_docker/clusterize'
          # {solr} = scd_ctxs[0].config.ryba
          # solr.cloud_docker.clusters ?= {}
          {solr} = @config.ryba
          solr.cloud_docker ?= {}
          solr.cloud_docker.clusters ?= {}
          cluster_config = ranger.admin.cluster_config = solr.cloud_docker.clusters[cluster_name]
          if not cluster_config?
            for solr_ctx in scd_ctxs
              solr = solr_ctx.config.ryba.solr ?= {}
              #By default Ryba search for a solr cloud cluster named ranger_cluster in config
              # Configures one cluster if not in config
              solr.cloud_docker.clusters ?= {}
              cluster_config  = solr.cloud_docker.clusters[cluster_name] ?= {}
              cluster_config.volumes ?= []
              cluster_config.volumes.push '/tmp/ranger_audits:/ranger_audits'
              cluster_config['containers'] ?= scd_ctxs.length
              cluster_config['master'] ?= scd_ctxs[0].config.host
              cluster_config['heap_size'] ?= '256m'
              cluster_config['port'] ?= 10000
              cluster_config.zk_opts ?= {}
              cluster_config['hosts'] ?= scd_ctxs.map (ctx) -> ctx.config.host
              solr_clusterize solr_ctx , cluster_name, cluster_config
            ranger.admin.cluster_config = scd_ctxs[0].config.ryba.solr.cloud_docker.clusters[cluster_name]
          if @params.command is 'install'
            scd_ctxs[0]
            .after
              type: ['docker','compose','up']
              target: "#{solr.cloud_docker.conf_dir}/clusters/#{cluster_name}/docker-compose.yml"
              handler: -> @call 'ryba/ranger/admin/solr_bootstrap'
            #Search for a cloud_docker cluster find in solr.cloud_docker.clusters
          ranger.admin.install['audit_solr_port'] ?= ranger.admin.cluster_config.port
          ranger.admin.cluster_config['ranger'] ?= {}
          if scd_ctxs.length > 0
            ranger.admin.install['audit_solr_zookeepers'] ?= "#{scd_ctxs[0].config.ryba.solr.cloud_docker.zk_connect}/solr_#{cluster_name}"
          else
            ranger.admin.install['audit_solr_zookeepers'] ?= 'NONE'
          solrs_urls = ranger.admin.cluster_config.hosts.map( (host) ->
           "#{if solr.cloud_docker.ssl.enabled  then 'https://' else 'http://'}#{host}:#{ranger.admin.cluster_config.port}/solr/ranger_audits").join(',')
          break;

## Solr Audit Database Bootstrap
Create the `ranger_audits` collection('cloud')/core('standalone').

      if ranger.admin.install['audit_store'] is 'solr'
        ranger.admin.install['audit_solr_urls'] ?= solrs_urls
        ranger.admin.install['audit_solr_user'] ?= 'ranger'
        ranger.admin.install['audit_solr_password'] ?= 'ranger123'
        # ranger.admin.install['audit_solr_zookeepers'] = 'NONE'

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
          ranger.admin.cluster_config.ranger.solr_users.push {
            name: "#{ranger.admin.install['audit_solr_user']}"
            secret:"#{ranger.admin.install['audit_solr_password']}"
          }

## Ranger Admin SSL
Configure SSL for Ranger policymanager (webui).

      ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] ?= 'true'
      ranger.admin.site['ranger.service.https.attrib.clientAuth'] ?= 'false'
      ranger.admin.site['ranger.service.https.attrib.keystore.file'] ?= '/etc/ranger/admin/conf/keystore'
      ranger.admin.site['ranger.service.https.attrib.keystore.pass'] ?= 'ryba123'
      ranger.admin.site['ranger.service.https.attrib.keystore.keyalias'] ?= @config.shortname

# Ranger Admin Databases
Configures the Ranger WEBUi (policymanager) database. For now only mysql is supported.

      ranger.admin.install['DB_FLAVOR'] ?= 'MYSQL' # we support only mysql for now
      switch ranger.admin.install['DB_FLAVOR'].toLowerCase()
        when 'mysql'
          ranger.admin.install['SQL_CONNECTOR_JAR'] ?= '/usr/hdp/current/ranger-admin/lib/mysql-connector-java.jar'
          # not setting these properties on purpose, we manage manually databases inside mysql
          ranger.admin.install['db_root_user'] = db_admin.mysql.admin_username
          ranger.admin.install['db_root_password'] ?= db_admin.mysql.admin_password
          if not ranger.admin.install['db_root_user'] and not ranger.admin.install['db_root_password']
          then throw new Error "account with privileges for creating database schemas and users is required"
          ranger.admin.install['db_host'] ?=  db_admin.mysql.host
          #Ranger Policy Database
          throw new Error "mysql host not specified" unless ranger.admin.install['db_host']
          ranger.admin.install['db_name'] ?= 'ranger'
          ranger.admin.install['db_user'] ?= 'rangeradmin'
          ranger.admin.install['db_password'] ?= 'rangeradmin123'
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
            [opldp_srv_ctx] = @contexts 'masson/core/openldap_server'
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

## Ranger PLUGINS
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
[ryba-cluster-conf]: https://github.com/ryba-io/ryba-cluster/blob/master/conf/config.coffee
[ranger-upgrade-24-25]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_command-line-upgrade/content/upgrade-ranger_24.html
