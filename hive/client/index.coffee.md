
# Hive & HCatolog Client
[Hive Client](https://cwiki.apache.org/confluence/display/Hive/HiveClient) is the application that you use in order to administer, use Hive.
Once installed you can type hive in a prompt and the hive client shell wil launch directly.


    module.exports = []

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

    module.exports.configure = (ctx) ->
      require('../../hadoop/hdfs').configure ctx
      require('../../tez').configure ctx
      require('../index').configure ctx
      {hive, mapred, tez} = ctx.config.ryba
      hive.client ?= {}
      hive.client.opts = ""
      hive.client.heapsize = 1024
      # Tuning
      # [Christian Prokopp comments](http://www.quora.com/What-are-the-best-practices-for-using-Hive-What-settings-should-we-enable-most-of-the-time)
      # [David Streever](https://streever.atlassian.net/wiki/display/HADOOP/Hive+Performance+Tips)
      # hive.site['hive.exec.compress.output'] ?= 'true'
      hive.site['hive.exec.compress.intermediate'] ?= 'true'
      hive.site['hive.auto.convert.join'] ?= 'true'
      hive.site['hive.cli.print.header'] ?= 'false'
      # hive.site['hive.mapjoin.smalltable.filesize'] ?= '50000000'

      hive.site['hive.execution.engine'] ?= 'tez'
      hive.site['hive.tez.container.size'] ?= tez.tez_site['tez.am.resource.memory.mb']
      hive.site['hive.tez.java.opts'] ?= tez.tez_site['hive.tez.java.opts']
      # Size per reducer. The default in Hive 0.14.0 and earlier is 1 GB. In
      # Hive 0.14.0 and later the default is 256 MB.
      # HDP set it to 64 MB which seems wrong
      # Don't know if this default value should be hardcoded or estimated based
      # on cluster capacity 
      hive.site['hive.exec.reducers.bytes.per.reducer'] ?= '268435456'

      # Import HCatalog properties
      hcat_ctx = ctx.contexts('ryba/hive/hcatalog', require('../hcatalog').configure)[0]
      throw Error "No HCatalog server declared" unless hcat_ctx
      properties = [
        'hive.metastore.uris'
        'hive.security.authorization.enabled'
        'hive.server2.authentication'
        # 'hive.security.authorization.manager'
        # 'hive.security.metastore.authorization.manager'
        # 'hive.security.authenticator.manager'
        # Transaction, read/write locks
        'hive.support.concurrency'
        'hive.zookeeper.quorum'
        'hive.enforce.bucketing'
        'hive.exec.dynamic.partition.mode'
        'hive.txn.manager'
        'hive.txn.timeout'
        'hive.txn.max.open.batch'
        'hive.cluster.delegation.token.store.zookeeper.connectString'
        'hive.cluster.delegation.token.store.class'
      ]
      for property in properties then hive.site[property] ?= hcat_ctx.config.ryba.hive.site[property]

## Commands

    module.exports.push commands: 'check', modules: 'ryba/hive/client/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hive/client/install'
      'ryba/hive/client/check'
    ]

## Notes

Example of a minimal client configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>hive.metastore.kerberos.keytab.file</name>
    <value>/etc/security/keytabs/hive.service.keytab</value>
  </property>
  <property>
    <name>hive.metastore.kerberos.principal</name>
    <value>hive/_HOST@ADALTAS.COM</value>
  </property>
  <property>
    <name>hive.metastore.sasl.enabled</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://big3.big:9083</value>
  </property>
</configuration>
```












