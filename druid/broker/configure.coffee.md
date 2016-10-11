
# Druid Broker Configure

## Tuning

Druid Brokers also benefit greatly from being tuned to the hardware they run on.
If you are using r3.2xlarge EC2 instances, or similar hardware, the
configuration in the distribution is a reasonable starting point.

If you are using different hardware, we recommend adjusting configurations for
your specific hardware. The most commonly adjusted configurations are:

*   `-Xmx and -Xms`
*   `druid.server.http.numThreads`
*   `druid.cache.sizeInBytes`
*   `druid.processing.buffer.sizeBytes`
*   `druid.processing.numThreads`
*   `druid.query.groupBy.maxIntermediateRows`
*   `druid.query.groupBy.maxResults`

## Example

```json
{ "ryba": { "druid": "broker": {
  "jvm": {
    "xms": "24g"
    "xmx": "24g"
} } } }
```

    module.exports  = handler: ->
      require('../configure').handler.call @
      {druid} = @config.ryba
      druid.broker ?= {}
      druid.broker.runtime ?= {}
      druid.broker.runtime['druid.service'] ?= 'druid/broker'
      druid.broker.runtime['druid.port'] ?= '8082'
      druid.broker.runtime['druid.broker.http.numConnections'] ?= '5'
      druid.broker.runtime['druid.server.http.numThreads'] ?= '25'
      druid.broker.runtime['druid.processing.buffer.sizeBytes'] ?= '536870912'
      druid.broker.runtime['druid.processing.numThreads'] ?= '7'
      druid.broker.runtime['druid.broker.cache.useCache'] ?= 'true'
      druid.broker.runtime['druid.broker.cache.populateCache'] ?= 'true'
      druid.broker.runtime['druid.cache.type'] ?= 'local'
      druid.broker.runtime['druid.cache.sizeInBytes'] ?= '2000000000'
      druid.broker.jvm ?= {}
      druid.broker.jvm.xms ?= '24g'
      druid.broker.jvm.xmx ?= '24g'
      
