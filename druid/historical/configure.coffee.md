
# Druid Historical Configure

## Tuning

Druid Historicals and MiddleManagers serve queries and can be co-located on the
same hardware. Both Druid processes benefit greatly from being tuned to the
hardware they run on. If you are running Tranquility Server or Kafka, you can
also colocate Tranquility with these two Druid processes. If you are using
r3.2xlarge EC2 instances, or similar hardware, the configuration in the
distribution is a reasonable starting point.

If you are using different hardware, we recommend adjusting configurations for
your specific hardware. The most commonly adjusted configurations are:

*   `-Xmx and -Xms`
*   `druid.server.http.numThreads`
*   `druid.processing.buffer.sizeBytes`
*   `druid.processing.numThreads`
*   `druid.query.groupBy.maxIntermediateRows`
*   `druid.query.groupBy.maxResults`
*   `druid.server.maxSize and druid.segmentCache.locations on Historical Nodes`
*   `druid.worker.capacity on MiddleManagers`


## Example

```json
{ "ryba": { "druid": "historical": {
  "jvm": {
    "xms": "8g"
    "xmx": "8g"
} } } }
```

    module.exports = ->
      {druid} = @config.ryba
      druid.historical ?= {}
      druid.historical.runtime ?= {}
      druid.historical.runtime['druid.service'] ?= 'druid/historical'
      druid.historical.runtime['druid.port'] ?= '8083'
      druid.historical.runtime['druid.server.http.numThreads'] ?= '25'
      druid.historical.runtime['druid.processing.buffer.sizeBytes'] ?= '536870912'
      druid.historical.runtime['druid.processing.numThreads'] ?= '7'
      druid.historical.runtime['druid.segmentCache.locations'] ?= '[{"path":"var/druid/segment-cache","maxSize"\:130000000000}]'
      druid.historical.runtime['druid.server.maxSize'] ?= '130000000000'
      druid.historical.jvm ?= {}
      druid.historical.jvm.xms ?= '8g'
      druid.historical.jvm.xmx ?= '8g'
      druid.historical.jvm.max_direct_memory_size ?= druid.historical.jvm.xmx # Default is 4G
