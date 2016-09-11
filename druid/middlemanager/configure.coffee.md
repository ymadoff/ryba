
# Druid MiddleManager Configure

Example:

```json
{
  "ryba": {
    "druid": "version": "0.9.1.1"
  }
}
```

    module.exports  = irreversible: true, handler: ->
      {druid} = @config.ryba
      hdp_version = '2.5.0.0-1245'
      druid.middlemanager_runtime ?= {}
      druid.middlemanager_runtime['druid.service'] ?= 'druid/middleManager'
      druid.middlemanager_runtime['druid.port'] ?= '8091'
      # Number of tasks per middleManager
      druid.middlemanager_runtime['druid.worker.capacity'] ?= '3'
      # Task launch parameters
      # Add "-Dhadoop.mapreduce.job.classloader=true" to avoid incompatible jackson versions
      # see https://github.com/druid-io/druid/blob/master/docs/content/operations/other-hadoop.md
      druid.middlemanager_runtime['druid.indexer.runner.javaOpts'] ?= "-server -Xmx2g -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -Dhadoop.mapreduce.job.classloader=true -Dhdp.version=#{hdp_version}"
      druid.middlemanager_runtime['druid.indexer.task.baseTaskDir'] ?= '/var/druid/task'
      # # HTTP server threads
      druid.middlemanager_runtime['druid.server.http.numThreads'] ?= '25'
      # Processing threads and buffers
      druid.middlemanager_runtime['druid.processing.buffer.sizeBytes'] ?= '536870912'
      druid.middlemanager_runtime['druid.processing.numThreads'] ?= '2'
      # Hadoop indexing
      druid.middlemanager_runtime['druid.indexer.task.hadoopWorkingPath'] ?= '/tmp/druid-indexing'
      # druid.middlemanager_runtime['druid.indexer.task.defaultHadoopCoordinate'] ?= '["org.apache.hadoop:hadoop-client:2.3.0"]'
      druid.middlemanager_runtime['druid.indexer.task.defaultHadoopCoordinate'] ?= '["org.apache.hadoop:hadoop-client:2.7.3"]'
