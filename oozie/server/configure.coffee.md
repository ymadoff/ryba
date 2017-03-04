
# Oozie Server Configure

*   `oozie.user` (object|string)
    The Unix Oozie login name or a user object (see Nikita User documentation).
*   `oozie.group` (object|string)
    The Unix Oozie group name or a group object (see Nikita Group documentation).

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

    module.exports = ->
      # Internal properties
      zk_ctxs = @contexts 'ryba/zookeeper/server'
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
      #jdbc provided by ryba/commons/db_admin
      #for now only setting the first host as Oozie fails to parse jdbc url.
      #JIRA: [OOZIE-2136]
      oozie.site['oozie.service.JPAService.jdbc.url'] ?= "jdbc:mysql://#{oozie.db.host}:#{oozie.db.port}/#{oozie.db.database}?createDatabaseIfNotExist=true"
      oozie.site['oozie.service.JPAService.jdbc.driver'] ?= 'com.mysql.jdbc.Driver'
      oozie.site['oozie.service.JPAService.jdbc.username'] ?= 'oozie'
      oozie.site['oozie.service.JPAService.jdbc.password'] ?= 'oozie123'
      # oozie.site['oozie.service.AuthorizationService.security.enabled'] ?= null # Now deprecated in favor of oozie.service.AuthorizationService.authorization.enabled (see oozie "oozie.log" file)
      # Path to hadoop configuration is required when running 'sharelib upgrade'
      # or an error will complain that the hdfs url is invalid
      oozie.site['oozie.service.HadoopAccessorService.hadoop.configurations'] ?= '*=/etc/hadoop/conf'
      # configuration for Spark
      oozie.site['oozie.service.SparkConfigurationService.spark.configurations'] ?= '*=/etc/spark/conf/'
      oozie.site['oozie.service.SparkConfigurationService.spark.configurations.ignore.spark.yarn.jar'] ?= 'true'
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
      oozie.site['oozie.action.shell.setup.hadoop.conf.dir.log4j.content'] ?= '''
      log4j.rootLogger=${hadoop.root.logger}
      hadoop.root.logger=INFO,console
      log4j.appender.console=org.apache.log4j.ConsoleAppender
      log4j.appender.console.target=System.err
      log4j.appender.console.layout=org.apache.log4j.PatternLayout
      log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{2}: %m%n
      '''

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
      ryba.oozie.log4j.opts ?= {}
      ryba.oozie.log4j.opts[k] ?= v for k, v of @config.log4j
      if ryba.oozie.log4j.opts.server_port?
        ryba.oozie.log4j.opts['extra_appender'] = ",socket_server"
      if ryba.oozie.log4j.opts.remote_host? && ryba.oozie.log4j.opts.remote_port?
        ryba.oozie.log4j.opts['extra_appender'] = ",socket_client"
      ryba.oozie.log4j_opts = ""
      ryba.oozie.log4j_opts += " -Doozie.log4j.#{k}=#{v}" for k, v of ryba.oozie.log4j.opts

## Oozie Environment

      ryba.oozie.heap_size ?= '256m'

## High Availability
Config [High Availability][oozie-ha]. They should be configured against
the same database. It uses zookeeper for enabling HA.

      oozie.ha = if zk_ctxs.length > 1 then true else false
      if oozie.ha
        quorum = for zk_ctx in zk_ctxs.filter( (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant')
          "#{zk_ctx.config.host}:#{zk_ctx.config.ryba.zookeeper.config['clientPort']}"
        oozie.site['oozie.zookeeper.connection.string'] ?= quorum.join ','
        oozie.site['oozie.zookeeper.namespace'] ?= 'oozie-ha'
        oozie.site['oozie.services.ext'] ?= [
          'org.apache.oozie.service.ZKLocksService'
          'org.apache.oozie.service.ZKXLogStreamingService'
          'org.apache.oozie.service.ZKJobsConcurrencyService'
          'org.apache.oozie.service.ZKUUIDService'
        ]
      oozie.site['oozie.instance.id'] ?= @config.host
      #ACL On zookeeper
      oozie.site['oozie.zookeeper.secure'] ?= 'true'
      oozie.site['oozie.service.ZKUUIDService.jobid.sequence.max'] ?= '99999999990'

[oozie-ha]:(https://oozie.apache.org/docs/4.2.0/AG_Install.html#High_Availability_HA)
