
# HiveServer2 Configuration

The following properties are required by knox in secured mode:

*   hive.server2.enable.doAs
*   hive.server2.allow.user.substitution
*   hive.server2.transport.mode
*   hive.server2.thrift.http.port
*   hive.server2.thrift.http.path

Example:

```json
{ "ryba": {
    "hive": {
      "server2": {
        "heapsize": "4096",
        "opts": "-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=130.98.196.54 -Dcom.sun.management.jmxremote.rmi.port=9526 -Dcom.sun.management.jmxremote.port=9526 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
      },
      "site": {
        "hive.server2.thrift.port": "10001"
      }
    }
} }
```

    module.exports = ->
      zoo_ctxs = @contexts 'ryba/zookeeper/server'
      hadoop_ctxs = @contexts ['ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      hcat_ctxs = @contexts 'ryba/hive/hcatalog'
      hs2_ctxs = @contexts 'ryba/hive/server2'
      hbase_master = @contexts 'ryba/hbase/master'
      hbase_client = @contexts 'ryba/hbase/client'
      hbase_ctxs = @contexts 'ryba/hbase/thrift'
      {core_site, hive, realm} = @config.ryba ?= {}
      {java_home} = @config.java
      # Layout and environment
      hive.server2 ?= {}
      hive.server2.conf_dir ?= '/etc/hive-server2/conf'
      hive.server2.log_dir ?= '/var/log/hive-server2'
      hive.server2.pid_dir ?= '/var/run/hive-server2'
      hive.server2.opts ?= ''
      hive.server2.heapsize ?= 1024

## Users & Groups

      # User
      hive.user ?= {}
      hive.user = name: hive.user if typeof hive.user is 'string'
      hive.user.name  = hcat_ctxs[0].config.ryba.hive.user.name ?= 'hive'
      hive.user.system =  hcat_ctxs[0].config.ryba.hive.user.system ?= true
      hive.user.groups = hcat_ctxs[0].config.ryba.hive.user.groups ?= 'hadoop'
      hive.user.comment = hcat_ctxs[0].config.ryba.hive.user.comment ?= 'Hive User'
      hive.user.home = hcat_ctxs[0].config.ryba.hive.user.home ?= '/var/lib/hive'
      hive.user.limits ?= {}
      hive.user.limits.nofile = hcat_ctxs[0].config.ryba.hive.user.limits.nofile ?= 64000
      hive.user.limits.nproc = hcat_ctxs[0].config.ryba.hive.user.limits.nproc ?= true
      # Group
      hive.group ?= {}
      hive.group = name: hive.group if typeof hive.group is 'string'
      hive.group.name = hcat_ctxs[0].config.ryba.hive.group.name ?= 'hive'
      hive.group.system = hcat_ctxs[0].config.ryba.hive.group.system ?= true
      hive.user.gid = hive.group.name
      hive.server2 ?= {}

## Configuration

      hive.server2.site ?= {}
      properties = [ # Duplicate client, might remove
        'hive.metastore.uris'
        'hive.metastore.sasl.enabled'
        'hive.security.authorization.enabled'
        'hive.security.authorization.manager'
        'hive.security.metastore.authorization.manager'
        'hive.security.authenticator.manager'
        'hive.optimize.mapjoin.mapreduce'
        'hive.enforce.bucketing'
        'hive.exec.dynamic.partition.mode'
        'hive.txn.manager'
        'hive.txn.timeout'
        'hive.txn.max.open.batch'
        # Transaction, read/write locks
        'hive.support.concurrency'
        'hive.cluster.delegation.token.store.zookeeper.connectString'
        'hive.cluster.delegation.token.store.zookeeper.znode'
        
        'hive.heapsize'
        'hive.exec.max.created.files'
        'hive.auto.convert.sortmerge.join.noconditionaltask'
      ]
      for property in properties
        hive.server2.site[property] ?= hcat_ctxs[0].config.ryba.hive.hcatalog.site[property]
      # Server2 specific properties
      hive.server2.site['hive.server2.thrift.sasl.qop'] ?= 'auth'
      hive.server2.site['hive.server2.enable.doAs'] ?= 'true'
      # hive.server2.site['hive.server2.enable.impersonation'] ?= 'true' # Mention in CDH5.3 but hs2 logs complains it doesnt exist
      hive.server2.site['hive.server2.allow.user.substitution'] ?= 'true'
      hive.server2.site['hive.server2.transport.mode'] ?= 'http'
      hive.server2.site['hive.server2.thrift.port'] ?= '10001'
      hive.server2.site['hive.server2.thrift.http.port'] ?= '10001'
      hive.server2.site['hive.server2.thrift.http.path'] ?= 'cliservice'
      # Bug fix: java properties are not interpolated
      # Default is "${system:java.io.tmpdir}/${system:user.name}/operation_logs"
      hive.server2.site['hive.server2.logging.operation.log.location'] ?= "/tmp/#{hive.user.name}/operation_logs"
      # Tez
      # https://streever.atlassian.net/wiki/pages/viewpage.action?pageId=4390918
      hive.server2.site['hive.server2.tez.default.queues'] ?= 'default'
      hive.server2.site['hive.server2.tez.sessions.per.default.queue'] ?= '1'
      hive.server2.site['hive.server2.tez.initialize.default.sessions'] ?= 'false'

## Hive Server2 Environment

      hive.server2.env ?= {}  
      #JMX Config
      hive.server2.env["JMX_OPTS"] ?= ''
      if hive.server2.env["JMXPORT"]? and hive.server2.env["JMX_OPTS"].indexOf('-Dcom.sun.management.jmxremote.rmi.port') is -1
        hive.server2.env["$JMXSSL"] ?= false
        hive.server2.env["$JMXAUTH"] ?= false
        hive.server2.env["JMX_OPTS"] += """
          -Dcom.sun.management.jmxremote \
          -Dcom.sun.management.jmxremote.authenticate=#{hive.server2.env["$JMXAUTH"]} \
          -Dcom.sun.management.jmxremote.ssl=#{hive.server2.env["$JMXSSL"]} \
          -Dcom.sun.management.jmxremote.port=#{hive.server2.env["JMXPORT"]} \
          -Dcom.sun.management.jmxremote.rmi.port=#{hive.server2.env["JMXPORT"]} \
          """
      aux_jars = ['/usr/hdp/current/hive-webhcat/share/hcatalog/hive-hcatalog-core.jar']
      if hbase_master.length and @config.host in hbase_client.map((ctx) -> ctx.config.host)
        aux_jars.push ['/usr/hdp/current/hbase-client/lib/hbase-server.jar', '/usr/hdp/current/hbase-client/lib/hbase-client.jar', '/usr/hdp/current/hbase-client/lib/hbase-common.jar']... # Default value
        aux_jars.push '/usr/hdp/current/hbase-client/lib/phoenix-server.jar' if @has_service 'ryba/phoenix/client'
      hive.server2.aux_jars ?= aux_jars.join ':'

## Configure Kerberos

      # https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2
      # Authentication type
      hive.server2.site['hive.server2.authentication'] ?= 'KERBEROS'
      # The keytab for the HiveServer2 service principal
      # 'hive.server2.authentication.kerberos.keytab': "/etc/security/keytabs/hcat.service.keytab"
      hive.server2.site['hive.server2.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/hive.service.keytab'
      # The service principal for the HiveServer2. If _HOST
      # is used as the hostname portion, it will be replaced.
      # with the actual hostname of the running instance.
      hive.server2.site['hive.server2.authentication.kerberos.principal'] ?= "hive/_HOST@#{realm}"
      # SPNEGO
      hive.server2.site['hive.server2.authentication.spnego.principal'] ?= core_site['hadoop.http.authentication.kerberos.principal']
      hive.server2.site['hive.server2.authentication.spnego.keytab'] ?= core_site['hadoop.http.authentication.kerberos.keytab']

## Configure SSL

      hive.server2.site['hive.server2.use.SSL'] ?= 'true'
      hive.server2.site['hive.server2.keystore.path'] ?= "#{hive.server2.conf_dir}/keystore"
      hive.server2.site['hive.server2.keystore.password'] ?= "ryba123"
      hive.server2.truststore_location ?= "#{hive.server2.conf_dir}/truststore"
      hive.server2.truststore_password ?= "ryba123"

## HS2 High Availability & Rolling Upgrade

HS2 use Zookeepper to track registered servers. The znode address is 
"/<hs2_namespace>/serverUri=<host:port>;version=<versionInfo>; sequence=<sequence_number>"
and its value is the server "host:port".

      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      hive.server2.site['hive.zookeeper.quorum'] ?= zookeeper_quorum.join ','
      hive.server2.site['hive.server2.support.dynamic.service.discovery'] ?= if hs2_ctxs.length > 1 then 'true' else 'false'
      hive.server2.site['hive.zookeeper.session.timeout'] ?= '600000' # Default is "600000"
      hive.server2.site['hive.server2.zookeeper.namespace'] ?= 'hiveserver2' # Default is "hiveserver2"

## Configuration for Proxy users

      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hive.user.name}.groups"] ?= '*'
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hive.user.name}.hosts"] ?= '*'

# Configure Log4J

      hive.server2.log4j ?= {}
      hive.server2.log4j[k] ?= v for k, v of @config.log4j
      config = hive.server2.log4j.config ?= {}
      config['hive.log.file'] ?= 'hiveserver2.log'
      config['hive.log.dir'] ?= "#{hive.server2.log_dir}"
      config['log4j.appender.EventCounter'] ?= 'org.apache.hadoop.hive.shims.HiveEventCounter'
      config['log4j.appender.console'] ?= 'org.apache.log4j.ConsoleAppender'
      config['log4j.appender.console.target'] ?= 'System.err'
      config['log4j.appender.console.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.console.layout.ConversionPattern'] ?= '%d{yy/MM/dd HH:mm:ss} %p %c{2}: %m%n'
      config['log4j.appender.console.encoding'] ?= 'UTF-8'
      config['log4j.appender.RFAS'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.RFAS.File'] ?= '${hive.log.dir}/${hive.log.file}'
      config['log4j.appender.RFAS.MaxFileSize'] ?= '20MB'
      config['log4j.appender.RFAS.MaxBackupIndex'] ?= '10'
      config['log4j.appender.RFAS.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.RFAS.layout.ConversionPattern'] ?= '%d{ISO8601} %-5p %c{2} - %m%n'
      config['log4j.appender.DRFA'] ?= 'org.apache.log4j.DailyRollingFileAppender'
      config['log4j.appender.DRFA.File'] ?= '${hive.log.dir}/${hive.log.file}'
      config['log4j.appender.DRFA.DatePattern'] ?= '.yyyy-MM-dd'
      config['log4j.appender.DRFA.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.DRFA.layout.ConversionPattern'] ?= '%d{ISO8601} %-5p %c{2} (%F:%M(%L)) - %m%n'
      config['log4j.appender.DAILY'] ?= 'org.apache.log4j.rolling.RollingFileAppender'
      config['log4j.appender.DAILY.rollingPolicy'] ?= 'org.apache.log4j.rolling.TimeBasedRollingPolicy'
      config['log4j.appender.DAILY.rollingPolicy.ActiveFileName'] ?= '${hive.log.dir}/${hive.log.file}'
      config['log4j.appender.DAILY.rollingPolicy.FileNamePattern'] ?= '${hive.log.dir}/${hive.log.file}.%d{yyyy-MM-dd}'
      config['log4j.appender.DAILY.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.DAILY.layout.ConversionPattern'] ?= '%d{dd MMM yyyy HH:mm:ss,SSS} %-5p [%t] (%C.%M:%L) %x - %m%n'
      config['log4j.appender.AUDIT'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.AUDIT.File'] ?= '${hive.log.dir}/hiveserver2_audit.log'
      config['log4j.appender.AUDIT.MaxFileSize'] ?= '20MB'
      config['log4j.appender.AUDIT.MaxBackupIndex'] ?= '10'
      config['log4j.appender.AUDIT.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.AUDIT.layout.ConversionPattern'] ?= '%d{ISO8601} %-5p %c{2} (%F:%M(%L)) - %m%n'

      hive.server2.log4j.appenders = ',RFAS'
      hive.server2.log4j.audit_appenders = ',AUDIT'
      if hive.server2.log4j.remote_host and hive.server2.log4j.remote_port
        hive.server2.log4j.appenders = hive.server2.log4j.appenders + ',SOCKET'
        hive.server2.log4j.audit_appenders = hive.server2.log4j.audit_appenders + ',SOCKET'
        config['log4j.appender.SOCKET'] ?= 'org.apache.log4j.net.SocketAppender'
        config['log4j.appender.SOCKET.Application'] ?= 'hiveserver2'
        config['log4j.appender.SOCKET.RemoteHost'] ?= hive.server2.log4j.remote_host
        config['log4j.appender.SOCKET.Port'] ?= hive.server2.log4j.remote_port

      config['log4j.category.DataNucleus'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.category.Datastore'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.category.Datastore.Schema'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.category.JPOX.Datastore'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.category.JPOX.Plugin'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.category.JPOX.MetaData'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.category.JPOX.Query'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.category.JPOX.General'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.category.JPOX.Enhancer'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.hadoop.conf.Configuration'] ?= 'ERROR' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.zookeeper'] ?= 'INFO' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.server.ServerCnxn'] ?= 'WARN' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.server.NIOServerCnxn'] ?= 'WARN' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.ClientCnxn'] ?= 'WARN' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.ClientCnxnSocket'] ?= 'WARN' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.ClientCnxnSocketNIO'] ?= 'WARN' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.ql.log.PerfLogger'] ?= '${hive.ql.log.PerfLogger.level}'
      config['log4j.logger.org.apache.hadoop.hive.ql.exec.Operator'] ?= 'INFO' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.serde2.lazy'] ?= 'INFO' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.metastore.ObjectStore'] ?= 'INFO' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.metastore.MetaStore'] ?= 'INFO' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.metastore.HiveMetaStore'] ?= 'INFO' + hive.server2.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.metastore.HiveMetaStore.audit'] ?= 'INFO' + hive.server2.log4j.audit_appenders
      config['log4j.additivity.org.apache.hadoop.hive.metastore.HiveMetaStore.audit'] ?= false
      config['log4j.logger.server.AsyncHttpConnection'] ?= 'OFF'
      config['hive.log.threshold'] ?= 'ALL'
      config['hive.root.logger'] ?= 'INFO' + hive.server2.log4j.appenders
      config['log4j.rootLogger'] ?= '${hive.root.logger}, EventCounter'
      config['log4j.threshold'] ?= '${hive.log.threshold}'

# Hive On HBase
Add Hive user as proxyuser    

      for hbase_ctx in hbase_ctxs
        hbase_ctx.config.ryba.core_site ?= {}
        hbase_ctx.config.ryba.core_site["hadoop.proxyuser.#{hive.user.name}.hosts"] ?= '*'
        hbase_ctx.config.ryba.core_site["hadoop.proxyuser.#{hive.user.name}.groups"] ?= '*'
