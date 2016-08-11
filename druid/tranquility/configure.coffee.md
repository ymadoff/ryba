
# Tranquility Configure

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
      {druid} = @config.ryba
      druid.tranquility ?= {}
      # Layout
      druid.tranquility.dir ?= '/opt/tranquility'
      # Package
      druid.tranquility.version ?= "0.8.0"
      druid.tranquility.source ?= "http://static.druid.io/tranquility/releases/tranquility-distribution-#{druid.tranquility.version}.tgz"
      
