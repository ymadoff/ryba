
# Configuration

    module.exports = handler: ->
      {core_site, hadoop_conf_dir} = @config.ryba
      spark = @config.ryba.spark ?= {}
      spark  = @config.ryba.spark ?= {}
      spark.conf ?= {}
      # Group
      spark.group ?= {}
      spark.group = name: spark.group if typeof spark.group is 'string'
      spark.group.name ?= 'spark'
      spark.group.system ?= true
      # User
      spark.user ?= {}
      spark.user = name: spark.user if typeof spark.user is 'string'
      spark.user.name ?= 'spark'
      spark.user.system ?= true
      spark.user.comment ?= 'Spark User'
      spark.user.home ?= '/var/run/spark'
      spark.user.groups ?= 'hadoop'
      spark.user.gid ?= spark.group.name

      
      # Configuration
      spark.conf = {}
      spark.conf['spark.master'] ?= "local[*]"
      # For [Spark on YARN deployments][[secu]], configuring spark.authenticate to true
      # will automatically handle generating and distributing the shared secret.
      # Each application will use a unique shared secret. 
      # wdavidw: not tested, work without it on spark 1.3
      spark.conf['spark.authenticate'] ?= "true"
      # This causes Spark applications running on this client to write their history to the directory that the history server reads.
      spark.conf['spark.eventLog.enabled'] ?= "true"
      spark.conf['spark.yarn.services'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryService"
      spark.conf['spark.history.provider'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryProvider"
      # Base directory in which Spark events are logged, if spark.eventLog.enabled is true.
      # Within this base directory, Spark creates a sub-directory for each application, and logs the events specific to the application in this directory.
      # Users may want to set this to a unified location like an HDFS directory so history files can be read by the history server.
      spark.conf['spark.eventLog.dir'] ?= "#{core_site['fs.defaultFS']}/user/#{spark.user.name}/applicationHistory"
      spark.conf['spark.history.fs.logDirectory'] ?= "#{spark.conf['spark.eventLog.dir']}"
      spark.client_dir ?= '/usr/hdp/current/spark-client'
      spark.conf_dir ?= '/etc/spark/conf'
      # For now on spark 1.3, [SSL is falling][secu] even after distributing keystore
      # and trustore on worker nodes as suggested in official documentation.
      # Maybe we shall share and deploy public keys instead of just the cacert
      # Disabling for now 
      spark.conf['spark.ssl.enabled'] ?= "false"
      spark.conf['spark.ssl.enabledAlgorithms'] ?= "MD5"
      spark.conf['spark.ssl.keyPassword'] ?= "ryba123"
      spark.conf['spark.ssl.keyStore'] ?= "#{spark.conf_dir}/keystore"
      spark.conf['spark.ssl.keyStorePassword'] ?= "ryba123"
      spark.conf['spark.ssl.protocol'] ?= "SSLv3"
      spark.conf['spark.ssl.trustStore'] ?= "#{spark.conf_dir}/trustore"
      spark.conf['spark.ssl.trustStorePassword'] ?= "ryba123"
      spark.conf['spark.eventLog.overwrite'] ?= 'true'
      spark.conf['spark.yarn.jar'] ?= "hdfs:///apps/#{spark.user.name}/spark-assembly.jar"
      spark.conf['spark.yarn.applicationMaster.waitTries'] = null # Deprecated in favor of "spark.yarn.am.waitTime"
      spark.conf['spark.yarn.am.waitTime'] ?= '10'
      spark.conf['spark.yarn.containerLauncherMaxThreads'] ?= '25'
      spark.conf['spark.yarn.driver.memoryOverhead'] ?= '384'
      spark.conf['spark.yarn.executor.memoryOverhead'] ?= '384'
      spark.conf['spark.yarn.max.executor.failures'] ?= '3'
      spark.conf['spark.yarn.preserve.staging.files'] ?= 'false'
      spark.conf['spark.yarn.queue'] ?= 'default'
      spark.conf['spark.yarn.scheduler.heartbeat.interval-ms'] ?= '5000'
      spark.conf['spark.yarn.services'] ?= 'org.apache.spark.deploy.yarn.history.YarnHistoryService'
      spark.conf['spark.yarn.submit.file.replication'] ?= '3'

[secu]: http://spark.apache.org/docs/latest/security.html

## Spark History Server Configure

We set by default the address and port of the spark web ui server
Those properties are not set by default to enable user to access log trought Yarn RM WEB UI
See ryba/spark/history_server/install.coffee.md doc for detailed information on history server.
In addition, if you want the YARN ResourceManager to link directly to the Spark History Server, 
you can set the spark.yarn.historyServer.address property in /etc/spark/conf/spark-defaults.conf:

      [shs_ctx] = @contexts 'ryba/spark/history_server', require('../history_server/index').configure
      if shs_ctx
        spark.conf['spark.yarn.historyServer.address'] ?= "#{shs_ctx.config.host}:#{shs_ctx.config.ryba.spark.conf['spark.history.ui.port']}"
      else
        # HDP 2.3 sandbox set it to SHS address. If we do this here
        spark.conf['spark.yarn.historyServer.address'] ?= null

## Spark Client Metrics

Configure the "metrics.properties" to connect Spark to a metrics collector like Ganglia or Graphite.
The metrics.properties file needs to be sent to every executor, 
and spark.metrics.conf=metrics.properties will tell all executors to load that file when initializing their respective MetricsSystems

      # spark.conf['spark.metrics.conf'] ?= 'metrics.properties'
      spark.conf['spark.metrics.conf'] ?= null # Error, spark complain it cant find if value is 'metrics.properties'    
      spark.conf['spark.yarn.dist.files'] ?= "file://#{spark.conf_dir}/metrics.properties"

      spark.metrics =
        'master.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
        'worker.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
        'driver.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
        'executor.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'

      graphite_ctxs = @contexts 'ryba/graphite/carbon', require('../../graphite/carbon/configure').handler
      if graphite_ctxs.length
        spark.metrics['*.sink.graphite.class'] = 'org.apache.spark.metrics.sink.GraphiteSink'
        spark.metrics['*.sink.graphite.host'] = graphite_ctxs.map( (ctx) -> ctx.config.host)
        spark.metrics['*.sink.graphite.port'] = graphite_ctxs[0].config.ryba.graphite.carbon_aggregator_port
        spark.metrics['*.sink.graphite.prefix'] = "#{graphite_ctxs[0].config.ryba.graphite.metrics_prefix}.spark"

      # TODO : metrics.MetricsSystem: Sink class org.apache.spark.metrics.sink.GangliaSink cannot be instantialized
      if false #ctx.host_with_module 'ryba/ganglia/collector'
        ganglia_ctx = @contexts('ryba/ganglia/collector', require('../../ganglia/collector/configure').handler)[0].config.ryba.ganglia
        spark.metrics['*.sink.ganglia.class'] = 'org.apache.spark.metrics.sink.GangliaSink'
        spark.metrics['*.sink.ganglia.host'] = graphite_ctx.map( (ctx) -> ctx.config.host)
        spark.metrics['*.sink.ganglia.port'] = ganglia_ctx.spark_port