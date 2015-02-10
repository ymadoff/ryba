
# Hive & HCat Client

    module.exports = []

    module.exports.configure = (ctx) ->
      require('../hadoop/hdfs').configure ctx
      require('./_').configure ctx
      {hive} = ctx.config.ryba
      server_ctxs = ctx.contexts modules: 'ryba/hive/server', require('./server').configure
      server_ctx = server_ctxs[0]
      hive.site['hive.metastore.uris'] ?= server_ctx.config.ryba.hive.site['hive.metastore.uris']

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












