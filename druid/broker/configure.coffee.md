
# Druid Broker Configure

Example:

```json
{
  "ryba": {
    "druid": "broker": {
      "jvm": {
        "xms": "24g"
        "xmx": "24g"
      }
    }
  }
}
```

    module.exports  = handler: ->
      require('../configure').handler.call @
      druid = @config.ryba.druid ?= {}
      druid.broker ?= {}
      druid.broker.jvm ?= {}
      druid.broker.jvm.xms ?= '24g'
      druid.broker.jvm.xmx ?= '24g'
      
