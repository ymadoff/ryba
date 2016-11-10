
# Druid MiddleManager Configure

Example:

```json
{ "ryba": { "druid": "coordinator": {
  "jvm": {
    "xms": "64m"
    "xmx": "64m"
} } } }
```

    module.exports = ->
      {druid} = @config.ryba
      hdp_version = '2.5.0.0-1245' # TODO: disover hdp version
      druid.hadoop_mapreduce_dir ?= '/usr/hdp/current/hadoop-mapreduce-client'
      druid.middlemanager ?= {}
      druid.middlemanager.runtime ?= {}
      druid.middlemanager.runtime['druid.service'] ?= 'druid/middleManager'
      druid.middlemanager.runtime['druid.port'] ?= '8091'
      # Number of tasks per middleManager
      druid.middlemanager.runtime['druid.worker.capacity'] ?= '3'
      # Task launch parameters
      # Add "-Dhadoop.mapreduce.job.classloader=true" to avoid incompatible jackson versions
      # see https://github.com/druid-io/druid/blob/master/docs/content/operations/other-hadoop.md
      druid.middlemanager.runtime['druid.indexer.runner.javaOpts'] ?= "-server -Xmx2g -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -Dhadoop.mapreduce.job.classloader=true -Dhdp.version=#{hdp_version}"
      druid.middlemanager.runtime['druid.indexer.task.baseTaskDir'] ?= '/var/druid/task'
      # # HTTP server threads
      druid.middlemanager.runtime['druid.server.http.numThreads'] ?= '25'
      # Processing threads and buffers
      druid.middlemanager.runtime['druid.processing.buffer.sizeBytes'] ?= '536870912'
      druid.middlemanager.runtime['druid.processing.numThreads'] ?= '2'
      # Hadoop indexing
      druid.middlemanager.runtime['druid.indexer.task.hadoopWorkingPath'] ?= '/tmp/druid-indexing'
      # druid.middlemanager.runtime['druid.indexer.task.defaultHadoopCoordinate'] ?= '["org.apache.hadoop:hadoop-client:2.3.0"]'
      druid.middlemanager.runtime['druid.indexer.task.defaultHadoopCoordinate'] ?= '["org.apache.hadoop:hadoop-client:2.7.3"]'
      druid.middlemanager.jvm ?= {}
      druid.middlemanager.jvm.xms ?= '64m'
      druid.middlemanager.jvm.xmx ?= '64m'
