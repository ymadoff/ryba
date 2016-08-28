
# Oozie Server Configure

*   `oozie.user` (object|string)
    The Unix Oozie login name or a user object (see Mecano User documentation).
*   `oozie.group` (object|string)
    The Unix Oozie group name or a group object (see Mecano Group documentation).

Example

```json
    "oozie": {
      "user": {
        "name": "oozie", "system": true, "gid": "oozie",
        "comment": "Oozie User", "home": "/var/lib/oozie"
      },
      "group": {
        "name": "Oozie", "system": true
      }
    }
```

    module.exports = handler: ->
      # Internal properties
      {ryba} = @config
      ryba.force_war ?= false
      # User
      oozie = ryba.oozie ?= {}
      oozie.user ?= {}
      oozie.user = name: oozie.user if typeof oozie.user is 'string'
      oozie.user.name ?= 'oozie'
      oozie.user.system ?= true
      oozie.user.gid ?= 'oozie'
      oozie.user.comment ?= 'Oozie User'
      oozie.user.home ?= '/var/lib/oozie'
      # Group
      oozie.group ?= {}
      oozie.group = name: oozie.group if typeof oozie.group is 'string'
      oozie.group.name ?= 'oozie'
      oozie.group.system ?= true
      # Layout
      oozie.conf_dir ?= '/etc/oozie/conf'
      oozie.data ?= '/var/db/oozie'
      oozie.log_dir ?= '/var/log/oozie'
      oozie.pid_dir ?= '/var/run/oozie'
      oozie.tmp_dir ?= '/var/tmp/oozie'
      oozie.server_dir ?= '/usr/hdp/current/oozie-client/oozie-server'
      # SSL
      oozie.secure ?= true
      # see comment in ../resources/oozie-env.sh.j2

      oozie.keystore_file ?= "#{oozie.conf_dir}/keystore"
      oozie.keystore_pass ?= 'oozie123'
      oozie.truststore_file ?= "#{oozie.conf_dir}/trustore"
      oozie.truststore_pass ?= 'oozie123'
      # Configuration
      oozie.site ?= {}
      ryba.oozie.http_port ?= if oozie.secure then 11443 else 11000
      ryba.oozie.admin_port ?= 11001
      if oozie.secure
        oozie.site['oozie.base.url'] = "https://#{@config.host}:#{ryba.oozie.http_port}/oozie"
      else
        oozie.site['oozie.base.url'] = "http://#{@config.host}:#{ryba.oozie.http_port}/oozie"
      # Configuration Database
      oozie.db ?= {}
      oozie.db.engine ?= 'mysql'
      oozie.db[k] ?= v for k, v of ryba.db_admin[oozie.db.engine]
      oozie.db.database ?= 'oozie'
      oozie.site['oozie.service.JPAService.jdbc.url'] ?= "jdbc:mysql://#{oozie.db.host}:#{oozie.db.port}/#{oozie.db.database}?createDatabaseIfNotExist=true"
      oozie.site['oozie.service.JPAService.jdbc.driver'] ?= 'com.mysql.jdbc.Driver'
      oozie.site['oozie.service.JPAService.jdbc.username'] ?= 'oozie'
      oozie.site['oozie.service.JPAService.jdbc.password'] ?= 'oozie123'
      # oozie.site['oozie.service.AuthorizationService.security.enabled'] ?= null # Now deprecated in favor of oozie.service.AuthorizationService.authorization.enabled (see oozie "oozie.log" file)
      # Path to hadoop configuration is required when running 'sharelib upgrade'
      # or an error will conplain that the hdfs url is invalid
      oozie.site['oozie.service.HadoopAccessorService.hadoop.configurations'] ?= '*=/etc/hadoop/conf'
      # oozie.site['oozie.service.AuthorizationService.security.enabled'] ?= 'true'
      oozie.site['oozie.service.AuthorizationService.authorization.enabled'] ?= 'true'
      oozie.site['oozie.service.HadoopAccessorService.kerberos.enabled'] ?= 'true'
      oozie.site['local.realm'] ?= "#{ryba.realm}"
      oozie.site['oozie.service.HadoopAccessorService.keytab.file'] ?= '/etc/oozie/conf/oozie.service.keytab'
      oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] ?= "oozie/#{@config.host}@#{ryba.realm}"
      oozie.site['oozie.authentication.type'] ?= 'kerberos'
      oozie.site['oozie.authentication.kerberos.principal'] ?= "HTTP/#{@config.host}@#{ryba.realm}"
      oozie.site['oozie.authentication.kerberos.keytab'] ?= '/etc/oozie/conf/spnego.service.keytab'
      # oozie.site['oozie.service.HadoopAccessorService.nameNode.whitelist'] = ''
      oozie.site['oozie.authentication.kerberos.name.rules'] ?= ryba.core_site['hadoop.security.auth_to_local']
      oozie.site['oozie.service.HadoopAccessorService.nameNode.whitelist'] ?= '' # Fix space value
      oozie.site['oozie.credentials.credentialclasses'] ?= [
       'hcat=org.apache.oozie.action.hadoop.HCatCredentials'
       'hbase=org.apache.oozie.action.hadoop.HbaseCredentials'
       'hive2=org.apache.oozie.action.hadoop.Hive2Credentials'
      ]
      oozie.site['oozie.services'] ?= [
        'org.apache.oozie.service.SchedulerService'
        'org.apache.oozie.service.InstrumentationService'
        'org.apache.oozie.service.MemoryLocksService'
        'org.apache.oozie.service.UUIDService'
        'org.apache.oozie.service.ELService'
        'org.apache.oozie.service.AuthorizationService'
        'org.apache.oozie.service.UserGroupInformationService'
        'org.apache.oozie.service.HadoopAccessorService'
        'org.apache.oozie.service.JobsConcurrencyService'
        'org.apache.oozie.service.URIHandlerService'
        'org.apache.oozie.service.DagXLogInfoService'
        'org.apache.oozie.service.SchemaService'
        'org.apache.oozie.service.LiteWorkflowAppService'
        'org.apache.oozie.service.JPAService'
        'org.apache.oozie.service.StoreService'
        'org.apache.oozie.service.SLAStoreService'
        'org.apache.oozie.service.DBLiteWorkflowStoreService'
        'org.apache.oozie.service.CallbackService'
        'org.apache.oozie.service.ActionService'
        'org.apache.oozie.service.ShareLibService'
        'org.apache.oozie.service.CallableQueueService'
        'org.apache.oozie.service.ActionCheckerService'
        'org.apache.oozie.service.RecoveryService'
        'org.apache.oozie.service.PurgeService'
        'org.apache.oozie.service.CoordinatorEngineService'
        'org.apache.oozie.service.BundleEngineService'
        'org.apache.oozie.service.DagEngineService'
        'org.apache.oozie.service.CoordMaterializeTriggerService'
        'org.apache.oozie.service.StatusTransitService'
        'org.apache.oozie.service.PauseTransitService'
        'org.apache.oozie.service.GroupsService'
        'org.apache.oozie.service.ProxyUserService'
        'org.apache.oozie.service.XLogStreamingService'
        'org.apache.oozie.service.JvmPauseMonitorService'
        'org.apache.oozie.service.SparkConfigurationService'
      ].join(',')

## Configuration for Proxy Users

      hadoop_ctxs = @contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{oozie.user.name}.hosts"] ?= (@contexts('ryba/oozie/server')).map((ctx) -> ctx.config.host).join ','
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{oozie.user.name}.groups"] ?= '*'

## Configuration for Hadoop

      oozie.hadoop_config ?= {}
      oozie.hadoop_config['mapreduce.jobtracker.kerberos.principal'] ?= "mapred/#{ryba.static_host}@#{ryba.realm}"
      oozie.hadoop_config['yarn.resourcemanager.principal'] ?= "yarn/#{ryba.static_host}@#{ryba.realm}"
      oozie.hadoop_config['dfs.namenode.kerberos.principal'] ?= "hdfs/#{ryba.static_host}@#{ryba.realm}"
      oozie.hadoop_config['mapreduce.framework.name'] ?= "yarn"

## Configuration for Log4J

      ryba.oozie.log4j ?= {}
      ryba.oozie.log4j[k] ?= v for k, v of @config.log4j
      ryba.oozie.log4j.extra_appender = "socket_server" if ryba.oozie.log4j.server_port?
      ryba.oozie.log4j.extra_appender = "socket_client" if ryba.oozie.log4j.remote_host? && ryba.oozie.log4j.remote_port?
