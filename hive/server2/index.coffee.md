
# Hive Server2

HiveServer2 (HS2) is a server interface that enables remote clients to execute
queries against Hive and retrieve the results. The current implementation, based
on Thrift RPC, is an improved version of HiveServer and supports multi-client
concurrency and authentication. It is designed to provide better support for
open API clients like JDBC and ODBC.

    module.exports = []

## Configure

The following properties are required by knox in secured mode:

*   hive.server2.enable.doAs
*   hive.server2.allow.user.substitution
*   hive.server2.transport.mode
*   hive.server2.thrift.http.port
*   hive.server2.thrift.http.path

Example:

```json
{
  "ryba": {
    "hive": {
      "server2": {
        "heapsize": "4096",
        "opts": "-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=130.98.196.54 -Dcom.sun.management.jmxremote.rmi.port=9526 -Dcom.sun.management.jmxremote.port=9526 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
      },
      "site": {
        "hive.server2.thrift.port": "10001"
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/commons/mysql_server').configure ctx
      require('../../hadoop/core').configure ctx
      require('../index').configure ctx
      {core_site, hive, static_host, realm} = ctx.config.ryba
      # Layout and environment
      hive.server2 ?= {}
      hive.server2.log_dir ?= '/var/log/hive-server2'
      hive.server2.pid_dir ?= '/var/run/hive-server2'
      hive.server2.opts ?= ''
      hive.server2.heapsize = 1024
      # Configuration
      hive.site ?= {}
      properties = [ # Duplicate client, might remove
        'hive.metastore.uris'
        'hive.security.authorization.enabled'
        'hive.security.authorization.manager'
        'hive.security.metastore.authorization.manager'
        'hive.security.authenticator.manager'
        # Transaction, read/write locks
        'hive.support.concurrency'
        'hive.zookeeper.quorum'
      ]
      for property in properties then hive.site[property] ?= hcat_ctx.config.ryba.hive.site[property]
      # Server2 specific properties
      hive.site['hive.server2.enable.doAs'] ?= 'true'
      # hive.site['hive.server2.enable.impersonation'] ?= 'true' # Mention in CDH5.3 but hs2 logs complains it doesnt exist
      hive.site['hive.server2.allow.user.substitution'] ?= 'true'
      hive.site['hive.server2.transport.mode'] ?= 'binary' # Kerberos not working with "http", see https://issues.apache.org/jira/browse/HIVE-6697
      hive.site['hive.server2.thrift.port'] ?= '10001'
      hive.site['hive.server2.thrift.http.port'] ?= '10001'
      hive.site['hive.server2.thrift.http.path'] ?= 'cliservice'
      # Bug fix: java properties are not interpolated
      # Default is "${system:java.io.tmpdir}/${system:user.name}/operation_logs"
      hive.site['hive.server2.logging.operation.log.location'] ?= "/tmp/#{hive.user.name}/operation_logs"
      # Tez
      # https://streever.atlassian.net/wiki/pages/viewpage.action?pageId=4390918
      hive.site['hive.server2.tez.default.queues'] ?= 'default'
      hive.site['hive.server2.tez.sessions.per.default.queue'] ?= '1'
      hive.site['hive.server2.tez.initialize.default.sessions'] ?= 'false'

## Configure Kerberos

      # https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2
      # Authentication type
      hive.site['hive.server2.authentication'] ?= 'KERBEROS'
      # The keytab for the HiveServer2 service principal
      # 'hive.server2.authentication.kerberos.keytab': "/etc/security/keytabs/hcat.service.keytab"
      hive.site['hive.server2.authentication.kerberos.keytab'] ?= '/etc/hive/conf/hive.service.keytab'
      # The service principal for the HiveServer2. If _HOST
      # is used as the hostname portion, it will be replaced.
      # with the actual hostname of the running instance.
      hive.site['hive.server2.authentication.kerberos.principal'] ?= "hive/#{static_host}@#{realm}"
      # SPNEGO
      hive.site['hive.server2.authentication.spnego.principal'] ?= core_site['hadoop.http.authentication.kerberos.principal']
      hive.site['hive.server2.authentication.spnego.keytab'] ?= core_site['hadoop.http.authentication.kerberos.keytab']
      

## Commands

    module.exports.push commands: 'backup', modules: 'ryba/hive/server2/backup'

    module.exports.push commands: 'check', modules: 'ryba/hive/server2/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hive/server2/install'
      'ryba/hive/server2/start'
      'ryba/hive/server2/wait'
      'ryba/hive/server2/check'
    ]

    module.exports.push commands: 'start', modules: [
      'ryba/hive/server2/start'
      'ryba/hive/server2/wait'
    ]

    module.exports.push commands: 'status', modules: 'ryba/hive/server2/status'

    module.exports.push commands: 'stop', modules: 'ryba/hive/server2/stop'




