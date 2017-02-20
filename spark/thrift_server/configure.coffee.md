
# Spark Thrift Server

    module.exports = ->
      {realm, core_site} = @config.ryba
      hs2_ctxs = @contexts 'ryba/hive/server2'
      sc_ctxs = @contexts 'ryba/spark/client'
      sc_ctx = sc_ctxs[0]
      [ynm_ctx] = @contexts 'ryba/hadoop/yarn_nm'
      {hadoop_conf_dir, ssl, ssl_server, ssl_client} = ynm_ctx.config.ryba
      throw Error 'Spark SQL Thrift Server must be installed on the same host than hive-server2' unless hs2_ctxs.map((ctx)-> ctx.config.host).indexOf(@config.host) > -1
      throw Error 'Spark SQL Thrift Server is useless without spark installed' unless sc_ctx?
      spark = @config.ryba.spark ?= {}
      spark.user = sc_ctx.config.ryba.spark.user
      spark.group = sc_ctx.config.ryba.spark.group
      # Layout

Spark SQL thrift server starts a custom instance of hive-server2, we use the same properties 
than the hive-server2 (available on the same host). We inherits from almost every properties.
Only port, execution engine and dynamic discovery change (not supported).

## Configuration

      spark.thrift ?= {}
      spark.thrift.user_name ?= @config.ryba.hive.user.name
      spark.thrift.log_dir ?= '/var/log/spark'
      spark.thrift.pid_dir ?= '/var/run/spark' 
      spark.thrift.conf_dir ?= '/etc/spark-thrift-server/conf'

### Hive server2 Configuration

      spark.thrift.hive_site ?= {}
      spark.thrift.hive_site['hive.server2.thrift.port'] ?= '10015'
      spark.thrift.hive_site['hive.server2.thrift.http.port'] ?= '10015'
      spark.thrift.hive_site['hive.server2.use.SSL'] ?= 'true'
      spark.thrift.hive_site['hive.server2.keystore.path'] ?= "#{spark.thrift.conf_dir}/keystore"
      spark.thrift.hive_site['hive.server2.keystore.password'] ?= 'ryba123'
      spark.thrift.hive_site['hive.execution.engine'] = 'mr'
      # Do not modify this property, hive server2 spark instance does not support zookeeper dynamic discovery
      spark.thrift.hive_site['hive.server2.support.dynamic.service.discovery'] = 'false' 

### Spark Defaults
Inherits some of the basic spark yarn-cluster based installation

      spark.thrift.conf ?= {}
      spark.thrift.conf['spark.master'] ?= 'yarn-client'
      spark.thrift.conf['spark.executor.memory'] ?= '512m'
      spark.thrift.conf['spark.driver.memory'] ?= '512m'

      for prop in [
        'spark.authenticate'
        'spark.authenticate.secret'
        'spark.eventLog.enabled'
        'spark.yarn.services'
        'spark.history.provider'
        'spark.eventLog.dir'
        'spark.history.fs.logDirectory'
        'spark.ssl.enabledAlgorithms'
        'spark.eventLog.overwrite'
        'spark.yarn.jar'
        'spark.yarn.applicationMaster.waitTries'
        'spark.yarn.am.waitTime'
        'spark.yarn.containerLauncherMaxThreads'
        'spark.yarn.driver.memoryOverhead'
        'spark.yarn.executor.memoryOverhead'
        'spark.yarn.max.executor.failures'
        'spark.yarn.preserve.staging.files'
        'spark.yarn.queue'
        'spark.yarn.scheduler.heartbeat.interval-ms'
        'spark.yarn.services'
        'spark.yarn.submit.file.replication'
      ] then spark.thrift.conf[prop] ?= sc_ctx.config.ryba.spark.conf[prop]


### Log4j Properties

      spark.thrift.log4j ?= {}
      spark.thrift.log4j['log4j.rootCategory'] ?= 'INFO, console'
      spark.thrift.log4j['log4j.appender.console'] ?= 'org.apache.log4j.ConsoleAppender'
      spark.thrift.log4j['log4j.appender.console.target'] ?= 'System.out'
      spark.thrift.log4j['log4j.appender.console.layout'] ?= 'org.apache.log4j.PatternLayout'
      spark.thrift.log4j['log4j.appender.console.layout.ConversionPattern'] ?= '%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n'


      # Settings to quiet third party logs that are too verbose
      spark.thrift.log4j['log4j.logger.org.spark-project.jetty'] ?= 'WARN'
      spark.thrift.log4j['log4j.logger.org.spark-project.jetty.util.component.AbstractLifeCycle'] ?= 'ERROR'
      spark.thrift.log4j['log4j.logger.org.apache.spark.repl.SparkIMain$exprTyper'] ?= 'INFO'
      spark.thrift.log4j['log4j.logger.org.apache.spark.repl.SparkILoop$SparkILoopInterpreter'] ?= 'INFO'
      spark.thrift.log4j['log4j.logger.org.apache.parquet'] ?= 'ERROR'
      spark.thrift.log4j['log4j.logger.parquet'] ?= 'ERROR'

      # SPARK-9183: Settings to avoid annoying messages when looking up nonexistent UDFs in SparkSQL with Hive support
      spark.thrift.log4j['log4j.logger.org.apache.hadoop.hive.metastore.RetryingHMSHandler'] ?= 'FATAL'
      spark.thrift.log4j['log4j.logger.org.apache.hadoop.hive.ql.exec.FunctionRegistry'] ?= 'ERROR'

### SSL

      spark.thrift.conf['spark.ssl.enabled'] ?= 'true'
      spark.thrift.conf['spark.ssl.protocol'] ?= 'SSLv3'
      spark.thrift.conf['spark.ssl.trustStore'] ?= ssl_client['ssl.client.truststore.location']
      spark.thrift.conf['spark.ssl.trustStorePassword'] ?= ssl_client['ssl.client.truststore.password']

### Kerberos
Spark SQL thrift server is runned in yarn through the hive server user, and must use the hive-server2's keytab

      spark.thrift.hive_site['hive.server2.authentication.kerberos.principal'] ?= @config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal']
      spark.thrift.hive_site['hive.server2.authentication.kerberos.keytab'] ?= @config.ryba.hive.server2.site['hive.server2.authentication.kerberos.keytab']
      spark.thrift.conf['spark.yarn.principal'] ?= @config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal'].replace '_HOST', @config.host
      spark.thrift.conf['spark.yarn.keytab'] ?= @config.ryba.hive.server2.site['hive.server2.authentication.kerberos.keytab']
      match = /^(.+?)[@\/]/.exec spark.thrift.conf['spark.yarn.principal']
      throw Error 'SQL Thrift Server principal must mach thrift user name' unless match[1] is spark.thrift.user_name

### Enable Yarn Job submission

      nm_ctxs = @contexts 'ryba/hadoop/yarn_nm'
      for nm_ctx in nm_ctxs
        nm_ctx.before
          type: 'service'
          name: 'hadoop-yarn-nodemanager'
          handler: -> 
            @group hs2_ctxs[0].config.ryba.hive.group
            @system.user hs2_ctxs[0].config.ryba.hive.user
            @mkdir
              target: hs2_ctxs[0].config.ryba.hive.user.home


[hdp-spark-sql]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/starting_sts.html)
