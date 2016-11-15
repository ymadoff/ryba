
# Spark History Server

    module.exports = ->
      spark_ctxs = @contexts 'ryba/spark/client'
      {realm, core_site, hadoop_conf_dir, ssl, ssl_server, ssl_client} = @config.ryba
      spark = @config.ryba.spark ?= {}
      spark.history ?= {}
      # Layout
      spark.history.pid_dir ?= '/var/run/spark'
      spark.history.conf_dir ?= '/etc/spark/conf'
      spark.history.log_dir ?= '/var/log/spark'
      # User
      spark.user ?= {}
      spark.user = name: spark.user if typeof spark.user is 'string'
      spark.user.name ?= 'spark'
      spark.user.system ?= true
      spark.user.comment ?= 'Spark User'
      spark.user.home ?= '/var/lib/spark'
      spark.user.groups ?= 'hadoop'
      # Group
      spark.group ?= {}
      spark.group = name: spark.group if typeof spark.group is 'string'
      spark.group.name ?= 'spark'
      spark.group.system ?= true
      spark.user.gid ?= spark.group.name

### Spark Defaults
Inherits some of the basic spark yarn-cluster based installation


      spark.history.conf ?= {}
      spark.history.conf['spark.history.provider'] ?= 'org.apache.spark.deploy.history.FsHistoryProvider'
      spark.history.conf['spark.history.fs.update.interval'] ?= '10s'
      spark.history.conf['spark.history.retainedApplications'] ?= '50'
      spark.history.conf['spark.history.ui.port'] ?= '18080'
      spark.history.conf['spark.yarn.historyServer.address'] ?= "#{@config.host}:#{spark.history.conf['spark.history.ui.port']}"
      spark.history.conf['spark.history.kerberos.enabled'] ?= if core_site['hadoop.http.authentication.type'] is 'kerberos' then 'true' else 'false'
      spark.history.conf['spark.history.kerberos.principal'] ?= "spark/#{@config.host}@#{realm}"
      spark.history.conf['spark.history.kerberos.keytab'] ?= '/etc/security/keytabs/spark.keytab'
      spark.history.conf['spark.history.ui.acls.enable'] ?= 'true'
      spark.history.conf['spark.history.fs.cleaner.enabled'] ?= 'false'
      spark.history.conf['spark.history.retainedApplications'] ?= '50'

      for spark_ctx in spark_ctxs
        for prop in [
          'spark.master'
          'spark.authenticate'
          'spark.authenticate.secret'
          'spark.eventLog.enabled'
          'spark.eventLog.dir'
          'spark.history.fs.logDirectory'
          'spark.yarn.services'
          'spark.ssl.enabledAlgorithms'
          'spark.eventLog.overwrite'
          'spark.yarn.jar'
          'spark.history.retainedApplications'
          'spark.yarn.applicationMaster.waitTries'
          'spark.yarn.am.waitTime'
          'spark.yarn.containerLauncherMaxThreads'
          'spark.yarn.driver.memoryOverhead'
          'spark.yarn.executor.memoryOverhead'
          'spark.yarn.max.executor.failures'
          'spark.yarn.preserve.staging.files'
          'spark.yarn.queue'
          'spark.yarn.scheduler.heartbeat.interval-ms'
          'spark.yarn.submit.file.replication'
        ] then spark.history.conf[prop] ?= spark_ctx.config.ryba.spark.conf[prop]

### Configure client


        spark_ctx.config.ryba.spark.conf['spark.history.provider'] = spark.history.conf['spark.history.provider']
        spark_ctx.config.ryba.spark.conf['spark.history.ui.port'] = spark.history.conf['spark.history.ui.port']
        spark_ctx.config.ryba.spark.conf['spark.yarn.historyServer.address'] = spark.history.conf['spark.yarn.historyServer.address']


### Log4j Properties

      spark.history.log4j ?= {}
      spark.history.log4j['log4j.rootCategory'] ?= 'INFO, console'
      spark.history.log4j['log4j.appender.console'] ?= 'org.apache.log4j.ConsoleAppender'
      spark.history.log4j['log4j.appender.console.target'] ?= 'System.out'
      spark.history.log4j['log4j.appender.console.layout'] ?= 'org.apache.log4j.PatternLayout'
      spark.history.log4j['log4j.appender.console.layout.ConversionPattern'] ?= '%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n'


      # Settings to quiet third party logs that are too verbose
      spark.history.log4j['log4j.logger.org.spark-project.jetty'] ?= 'WARN'
      spark.history.log4j['log4j.logger.org.spark-project.jetty.util.component.AbstractLifeCycle'] ?= 'ERROR'
      spark.history.log4j['log4j.logger.org.apache.spark.repl.SparkIMain$exprTyper'] ?= 'INFO'
      spark.history.log4j['log4j.logger.org.apache.spark.repl.SparkILoop$SparkILoopInterpreter'] ?= 'INFO'
      spark.history.log4j['log4j.logger.org.apache.parquet'] ?= 'ERROR'
      spark.history.log4j['log4j.logger.parquet'] ?= 'ERROR'

      # SPARK-9183: Settings to avoid annoying messages when looking up nonexistent UDFs in SparkSQL with Hive support
      spark.history.log4j['log4j.logger.org.apache.hadoop.hive.metastore.RetryingHMSHandler'] ?= 'FATAL'
      spark.history.log4j['log4j.logger.org.apache.hadoop.hive.ql.exec.FunctionRegistry'] ?= 'ERROR'

### SSL

      spark.history.conf['spark.ssl.enabled'] ?= 'true'
      spark.history.conf['spark.ssl.protocol'] ?= 'SSLv3'
      spark.history.conf['spark.ssl.trustStore'] ?= ssl_client['ssl.client.truststore.location']
      spark.history.conf['spark.ssl.trustStorePassword'] ?= ssl_client['ssl.client.truststore.password']

### Kerberos
Spark History Server server is runned as the spark user

      spark.history.conf['spark.history.kerberos.enabled'] ?= if core_site['hadoop.http.authentication.type'] is 'kerberos' then 'true' else 'false'
      spark.history.conf['spark.history.kerberos.principal'] ?= "spark/#{@config.host}@#{realm}"
      spark.history.conf['spark.history.kerberos.keytab'] ?= '/etc/security/keytabs/spark.history.service.keytab'
