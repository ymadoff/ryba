
# Druid Coordinator Configure

Example:

```json
{ "ryba": { "druid": "coordinator": {
  "jvm": {
    "xms": "3g"
    "xmx": "3g"
} } } }
```

    module.exports = ->
      {druid} = @config.ryba
      druid.coordinator ?= {}
      druid.coordinator.runtime ?= {}
      druid.coordinator.runtime['druid.service'] ?= 'druid/coordinator'
      druid.coordinator.runtime['druid.port'] ?= '8081'
      druid.coordinator.runtime['druid.coordinator.startDelay'] ?= 'PT30S'
      druid.coordinator.runtime['druid.coordinator.period'] ?= 'PT30S'
      druid.coordinator.jvm ?= {}
      druid.coordinator.jvm.xms ?= '3g'
      druid.coordinator.jvm.xmx ?= '3g'
      
