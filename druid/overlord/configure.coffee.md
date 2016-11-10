
# Druid Overlord Configure

Example:

```json
{ "ryba": { "druid": "overlord": {
  "jvm": {
    "xms": "3g"
    "xmx": "3g"
} } } }
```

    module.exports = ->
      {druid} = @config.ryba
      druid.overlord ?= {}
      druid.overlord.runtime ?= {}
      druid.overlord.runtime['druid.service'] ?= 'druid/overlord'
      druid.overlord.runtime['druid.port'] ?= '8090'
      druid.overlord.runtime['druid.indexer.queue.startDelay'] ?= 'PT30S'
      druid.overlord.runtime['druid.indexer.runner.type'] ?= 'remote'
      druid.overlord.runtime['druid.indexer.storage.type'] ?= 'metadata'
      druid.overlord.jvm ?= {}
      druid.overlord.jvm.xms ?= '3g'
      druid.overlord.jvm.xmx ?= '3g'
