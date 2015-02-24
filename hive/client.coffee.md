
# Hive & HCat Client

    module.exports = []

    module.exports.configure = (ctx) ->
      require('../hadoop/hdfs').configure ctx
      require('../tez').configure ctx
      require('./_').configure ctx
      {hive, mapred, tez} = ctx.config.ryba
      server_ctxs = ctx.contexts modules: 'ryba/hive/server', require('./server').configure
      server_ctx = server_ctxs[0]
      hive.site['hive.metastore.uris'] ?= server_ctx.config.ryba.hive.site['hive.metastore.uris']
      # Tuning
      # [Christian Prokopp comments](http://www.quora.com/What-are-the-best-practices-for-using-Hive-What-settings-should-we-enable-most-of-the-time)
      # [David Streever](https://streever.atlassian.net/wiki/display/HADOOP/Hive+Performance+Tips)
      # hive.site['hive.exec.compress.output'] ?= 'true'
      hive.site['hive.exec.compress.intermediate'] ?= 'true'
      hive.site['hive.auto.convert.join'] ?= 'true'
      # hive.site['hive.mapjoin.smalltable.filesize'] ?= '50000000'

      hive.site['hive.tez.container.size'] = tez.tez_site['tez.am.resource.memory.mb']
      hive.site['hive.tez.java.opts'] = tez.tez_site['hive.tez.java.opts']

      # Import transactions

      hive.site['hive.support.concurrency'] = server_ctx.config.ryba.hive.site['hive.support.concurrency']
      hive.site['hive.enforce.bucketing'] = server_ctx.config.ryba.hive.site['hive.enforce.bucketing']
      hive.site['hive.exec.dynamic.partition.mode'] = server_ctx.config.ryba.hive.site['hive.exec.dynamic.partition.mode']
      hive.site['hive.txn.manager'] = server_ctx.config.ryba.hive.site['hive.txn.manager']
      hive.site['hive.txn.timeout'] = server_ctx.config.ryba.hive.site['hive.txn.timeout']
      hive.site['hive.txn.max.open.batch'] = server_ctx.config.ryba.hive.site['hive.txn.max.open.batch']

## Commands

    module.exports.push commands: 'check', modules: 'ryba/hive/client_check'

    module.exports.push commands: 'install', modules: [
      'ryba/hive/client_install'
      'ryba/hive/client_check'
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












