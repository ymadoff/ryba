# Spark Client

    module.exports = []

## Spark Configuration

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      require('../../hadoop/core').configure ctx
      require("../../hive/client").configure ctx
      require('../default').configure ctx
      {core_site, hadoop_conf_dir} = ctx.config.ryba
      {ryba} = ctx.config
      spark = ctx.config.ryba.spark ?= {}
      spark.client_dir ?= '/usr/hdp/current/spark-client'
      spark.conf_dir ?= '/etc/spark/conf'
      
      # Configuration
      spark.conf = {}
      # This causes Spark applications running on this client to write their history to the directory that the history server reads.
      spark.conf['spark.eventLog.enabled'] ?= "true"
      spark.conf['spark.yarn.services'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryService"
      spark.conf['spark.history.provider'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryProvider"
      spark.conf['spark.ssl.enabled'] ?= "true"
      spark.conf['spark.ssl.enabledAlgorithms'] ?= "MD5"
      spark.conf['spark.ssl.keyPassword'] ?= "ryba123"
      spark.conf['spark.ssl.keyStore'] ?= "#{spark.conf_dir}/keystore"
      spark.conf['spark.ssl.keyStorePassword'] ?= "ryba123"
      spark.conf['spark.ssl.protocol'] ?= "SSLv3"
      spark.conf['spark.ssl.trustStore'] ?= "#{spark.conf_dir}/trustore"
      spark.conf['spark.ssl.trustStorePassword'] ?= "ryba123"

## Spark History Server Configure

We set by default the address and port of the spark web ui server
Those properties are not set by default to enable user to access log trought Yarn RM WEB UI
See ryba/spark/history_server/install.coffee.md doc for detailed information on history server.
In addition, if you want the YARN ResourceManager to link directly to the Spark History Server, 
you can set the spark.yarn.historyServer.address property in /etc/spark/conf/spark-defaults.conf:

      [shs_ctx] = ctx.contexts 'ryba/spark/history_server', require('../history_server/index').configure
      if shs_ctx
        spark.conf['spark.yarn.historyServer.address'] ?= "#{shs_ctx.config.host}:#{shs_ctx.config.ryba.spark.conf['spark.history.ui.port']}"
      else
        # HDP 2.3 sandbox set it to SHS address. If we do this here
        spark.conf['spark.yarn.historyServer.address'] ?= null

## Spark Client Metrics

Configure the "metrics.properties" to connect Spark to a metrics collector like Ganglia or Graphite.
The metrics.properties file needs to be sent to every executor, 
and spark.metrics.conf=metrics.properties will tell all executors to load that file when initializing their respective MetricsSystems

      spark.conf['spark.metrics.conf'] ?= 'metrics.properties'
      spark.conf['spark.yarn.dist.files'] ?= "file://#{spark.conf_dir}/metrics.properties"

      spark.metrics =
        'master.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
        'worker.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
        'driver.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
        'executor.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'

      if ctx.host_with_module 'ryba/graphite/carbon'
        graphite_ctx = ctx.contexts('ryba/graphite/carbon', require('../../graphite/carbon').configure)[0].config.ryba.graphite
        spark.metrics['*.sink.graphite.class'] = 'org.apache.spark.metrics.sink.GraphiteSink'
        spark.metrics['*.sink.graphite.host'] = ctx.host_with_module 'ryba/graphite/carbon'
        spark.metrics['*.sink.graphite.port'] = graphite_ctx.carbon_aggregator_port
        spark.metrics['*.sink.graphite.prefix'] = "#{graphite_ctx.metrics_prefix}.spark"

      # TODO : metrics.MetricsSystem: Sink class org.apache.spark.metrics.sink.GangliaSink cannot be instantialized
      if false #ctx.host_with_module 'ryba/ganglia/collector'
        ganglia_ctx = ctx.contexts('ryba/ganglia/collector', require('../../ganglia/collector').configure)[0].config.ryba.ganglia
        spark.metrics['*.sink.ganglia.class'] = 'org.apache.spark.metrics.sink.GangliaSink'
        spark.metrics['*.sink.ganglia.host'] = ctx.host_with_module 'ryba/ganglia/collector'
        spark.metrics['*.sink.ganglia.port'] = ganglia_ctx.spark_port

    module.exports.push commands: 'install', modules: [
      'ryba/spark/client/install'
      'ryba/spark/client/check'
    ]

    module.exports.push commands: 'check', modules: 'ryba/spark/client/check'
