
# Hive Client Configuration

Example:

```json
{
  "ryba": {
    "hive": {
      "client": {
        opts": "-Xmx4096m",
        heapsize": "1024"
      }
    }
  }
}
```

    module.exports = ->
      hs2_ctxs = @contexts 'ryba/hive/server2'
      hcat_ctxs = @contexts 'ryba/hive/hcatalog'
      throw Error "No Hive Server2 server declared" unless hs2_ctxs.length
      throw Error "No Hive HCatalog declared" unless hcat_ctxs.length
      hive = @config.ryba.hive ?= {}
      hive.client ?= {}
      hive.client.opts = ""
      hive.client.heapsize = 1024
      hive.conf_dir ?= '/etc/hive/conf'
      hive.client.aux_jars ?= hcat_ctxs[0].config.ryba.hive.hcatalog.aux_jars

## Users & Groups

      hive.user = merge hive.user, hs2_ctxs[0].config.ryba.hive.user
      hive.group = merge hive.group, hs2_ctxs[0].config.ryba.hive.group

## Client HiveServer2 Configuration

      for property in [
        'hive.server2.authentication'
        # Transaction, read/write locks
        'hive.execution.engine'
        'hive.zookeeper.quorum'
        'hive.server2.thrift.sasl.qop'
        'hive.optimize.mapjoin.mapreduce'
        'hive.heapsize'
        'hive.auto.convert.sortmerge.join.noconditionaltask'
        'hive.exec.max.created.files'
      ] then hive.site[property] ?= hs2_ctxs[0].config.ryba.hive.server2.site[property]

## Configure SSL

      hive.client.truststore_location ?= "#{hive.conf_dir}/truststore"
      hive.client.truststore_password ?= "ryba123"

## Dependencies

    {merge} = require 'nikita/lib/misc'
