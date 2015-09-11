# Spark Client

Altiscale describes Spark usage in its [Tips and Tricks for Running Spark][tips]
article. Here's an extract from the original article.

Once installed, Spark can be run in three modes: local, yarn-client or
yarn-cluster.

*   Local mode: this launches a single Spark shell with all Spark components
    running within the same JVM. This is good for debugging on your laptop or on
    a workbench. Here’s how you’d invoke Spark in local mode:   
    ```
    cd $SPARK_HOME
    ./bin/spark-shell
    ```

*   Yarn-cluster: the Spark driver runs within the Hadoop cluster as a YARN
    Application Master and spins up Spark executors within YARN containers. This
    allows Spark applications to run within the Hadoop cluster and be completely
    decoupled from the workbench, which is used only for job submission. An
    example:   
    ```
    cd $SPARK_HOME
    ./bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn –deploy-mode cluster --num-executors 3 --driver-memory 1g --executor-memory 2g --executor-cores 1 --queue thequeue $SPARK_HOME/examples/target/spark-examples_*-1.2.1.jar`   
    ```
    Note that in the example above, the –queue option is used to specify the Hadoop queue to which the application is submitted.

*   Yarn-client: the Spark driver runs on the workbench itself with the
    Application Master operating in a reduced role. It only requests resources
    from YARN to ensure the Spark workers reside in the Hadoop cluster within
    YARN containers. This provides an interactive environment with distributed
    operations. Here’s an example of invoking Spark in this mode while ensuring
    it picks up the Hadoop LZO codec:   
    ```
    cd $SPARK_HOME
    bin/spark-shell --master yarn --deploy-mode client --queue research --driver-memory 512M --driver-class-path /opt/hadoop/share/hadoop/mapreduce/lib/hadoop-lzo-0.4.18-201409171947.jar
    ```

The three Spark modes have different use cases. Local and yarn-client modes are
both “shells,” allow initial, exploratory development, local mode restricted to
the computing power of your laptop, client mode able to leverage the full power
of your cluster.

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
      # For [Spark on YARN deployments][[secu]], configuring spark.authenticate to true
      # will automatically handle generating and distributing the shared secret.
      # Each application will use a unique shared secret. 
      # wdavidw: not tested, work without it on spark 1.3
      spark.conf['spark.authenticate'] ?= "true"
      # This causes Spark applications running on this client to write their history to the directory that the history server reads.
      spark.conf['spark.eventLog.enabled'] ?= "true"
      spark.conf['spark.yarn.services'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryService"
      spark.conf['spark.history.provider'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryProvider"
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

[secu]: http://spark.apache.org/docs/latest/security.html

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

[tips]: https://www.altiscale.com/hadoop-blog/spark-on-hadoop/
