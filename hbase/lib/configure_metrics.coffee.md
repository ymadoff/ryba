
## Configuration for metrics

Configuration of HBase metrics system.

The File sink is activated by default. The Ganglia and Graphite sinks are
automatically activated if the "ryba/ganglia/collector" and
"ryba/graphite/collector" are respectively registered on one of the nodes of the
cluster. You can disable any of those sinks by setting its class to "false", here
how:

```json
{ "ryba": { hbase: {"metrics": 
  "*.sink.file.class": false, 
  "*.sink.ganglia.class": false, 
  "*.sink.graphite.class": false
 } } }
```

Metrics can be filtered by context (in this exemple "master", "regionserver",
"jvm" and "ugi"). The list of available contexts can be obtained from HTTP, read
the [HBase documentation](http://hbase.apache.org/book.html#_hbase_metrics) for
additionnal informations.

```json
{ "ryba": { hbase: {"metrics": 
  "hbase.sink.file-all.filename": "hbase-metrics-all.out",
  "hbase.sink.file-master.filename": "hbase-metrics-master.out",
  "hbase.sink.file-master.context": "mastert",
  "hbase.sink.file-regionserver.filename": "hbase-metrics-regionserver.outt",
  "hbase.sink.file-regionserver.context": "regionservert",
  "hbase.sink.file-jvm.filename": "hbase-metrics-jvm.outt",
  "hbase.sink.file-jvm.context": "jvmt",
  "hbase.sink.file-ugi.filename": "hbase-metrics-ugi.outt",
  "hbase.sink.file-ugi.context": "ugit"
 } } }
```

According to the default "hadoop-metrics-hbase.properties", the list of
supported contexts are "hbase", "jvm" and "rpc".

    module.exports = ->
      hbase = @config.ryba.hbase
      hbase.metrics ?= {}
      hbase.metrics['*.period'] ?= '60'
      # File sink
      if hbase.metrics['*.sink.file.class']
        # hbase.metrics['*.sink.file.class'] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        hbase.metrics['hbase.sink.file.filename'] ?= 'metrics.out' # Default location is "/var/run/hbase/metrics.out"
        hbase.metrics['hbase.sink.file.filename'] ?= 'hbase-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      [ganglia_ctx] =  @contexts 'ryba/ganglia/collector', require('../../ganglia/collector').configure
      if ganglia_ctx and (hbase.metrics['*.sink.ganglia.class'] or hbase.metrics['*.sink.ganglia.class'] is undefined)
        hbase.metrics['*.sink.ganglia.class'] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
        hbase.metrics['*.sink.ganglia.period'] ?= '10'
        hbase.metrics['*.sink.ganglia.supportsparse'] ?= 'true' # Cant find definition but majority of examples are "true"
        hbase.metrics['*.sink.ganglia.slope'] ?= 'jvm.metrics.gcCount=zero,jvm.metrics.memHeapUsedM=both'
        hbase.metrics['*.sink.ganglia.dmax'] ?= 'jvm.metrics.threadsBlocked=70,jvm.metrics.memHeapUsedM=40'
        hbase.metrics['hbase.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        hbase.metrics['jvm.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        hbase.metrics['rpc.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
      # Graphite sink, accepted properties are "server_host", "server_port" and "metrics_prefix"
      [graphite_ctx] =  @contexts 'ryba/graphite/collector'
      if graphite_ctx and (hbase.metrics['*.sink.graphite.class'] or hbase.metrics['*.sink.graphite.class'] is undefined)
        hbase.metrics['*.sink.graphite.class'] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        hbase.metrics['*.sink.graphite.period'] ?= '10'
        hbase.metrics['hbase.sink.ganglia.server_host'] ?= "#{graphite_ctx.config.host}:#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
        hbase.metrics['hbase.sink.ganglia.server_port'] ?= "#{graphite_ctx.config.host}:#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
        hbase.metrics['jvm.sink.ganglia.server_host'] ?= "#{graphite_ctx.config.host}:#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
        hbase.metrics['jvm.sink.ganglia.server_port'] ?= "#{graphite_ctx.config.host}:#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
        hbase.metrics['rpc.sink.ganglia.server_host'] ?= "#{graphite_ctx.config.host}:#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"
        hbase.metrics['rpc.sink.ganglia.server_port'] ?= "#{graphite_ctx.config.host}:#{graphite_ctx.config.ryba.graphite.carbon_aggregator_port}"

  
