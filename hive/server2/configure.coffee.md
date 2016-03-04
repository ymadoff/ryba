
## HiveServer2 Configuration

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

    module.exports = handler: ->
      {core_site, hive, static_host, realm} = @config.ryba ?= {}
      hcat_ctxs = @contexts 'ryba/hive/hcatalog', require('../hcatalog/configure').handler
      # Layout and environment
      hive.server2 ?= {}
      hive.server2.conf_dir ?= '/etc/hive/conf'
      hive.server2.log_dir ?= '/var/log/hive-server2'
      hive.server2.pid_dir ?= '/var/run/hive-server2'
      hive.server2.opts ?= ''
      hive.server2.heapsize ?= 1024
      hive.conf_dir ?= '/etc/hive/conf'
      
## Users & Groups
      
      # User
      hive.user ?= {}
      hive.user = name: hive.user if typeof hive.user is 'string'
      hive.user.name  = hcat_ctxs[0].config.ryba.hive.user.name ?= 'hive'
      hive.user.system =  hcat_ctxs[0].config.ryba.hive.user.system ?= true
      hive.user.groups = hcat_ctxs[0].config.ryba.hive.user.groups ?= 'hadoop'
      hive.user.comment = hcat_ctxs[0].config.ryba.hive.user.comment ?= 'Hive User'
      hive.user.home = hcat_ctxs[0].config.ryba.hive.user.home ?= '/var/lib/hive'
      hive.user.limits ?= {}
      hive.user.limits.nofile = hcat_ctxs[0].config.ryba.hive.user.limits.nofile ?= 64000
      hive.user.limits.nproc = hcat_ctxs[0].config.ryba.hive.user.limits.nproc ?= true
      # Group
      hive.group ?= {}
      hive.group = name: hive.group if typeof hive.group is 'string'
      hive.group.name = hcat_ctxs[0].config.ryba.hive.group.name ?= 'hive'
      hive.group.system = hcat_ctxs[0].config.ryba.hive.group.system ?= true
      hive.user.gid = hive.group.name

## Configuration

      hive.aux_jars = hcat_ctxs[0].config.ryba.hive.aux_jars ?= []
      hive.site ?= {}
      # properties = [ # Duplicate client, might remove
      #   'hive.metastore.uris'
      #   'hive.security.authorization.enabled'
      #   'hive.security.authorization.manager'
      #   'hive.security.metastore.authorization.manager'
      #   'hive.security.authenticator.manager'
      #   # Transaction, read/write locks
      #   'hive.support.concurrency'
      #   'hive.zookeeper.quorum'
      # ]
      # for property in properties
      #   hive.site[property] ?= hcat_ctx.config.ryba.hive.site[property]
      # Server2 specific properties
      hive.site['hive.server2.enable.doAs'] ?= 'true'
      # hive.site['hive.server2.enable.impersonation'] ?= 'true' # Mention in CDH5.3 but hs2 logs complains it doesnt exist
      hive.site['hive.server2.allow.user.substitution'] ?= 'true'
      hive.site['hive.server2.transport.mode'] ?= 'http'
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

## Configure SSL

      hive.site['hive.server2.use.SSL'] ?= 'true'
      hive.site['hive.server2.keystore.path'] ?= "#{hive.server2.conf_dir}/keystore"
      hive.site['hive.server2.keystore.password'] ?= "ryba123"
  

## HS2 High Availability & Rolling Upgrade

HS2 use Zookeepper to track registered servers. The znode address is 
"/<hs2_namespace>/serverUri=<host:port>;version=<versionInfo>; sequence=<sequence_number>"
and its value is the server "host:port".

      zoo_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      hive.site['hive.zookeeper.quorum'] ?= zookeeper_quorum.join ','
      hs2_ctxs = @contexts 'ryba/hive/server2'
      hive.site['hive.server2.support.dynamic.service.discovery'] ?= if hs2_ctxs.length > 1 then 'true' else 'false'
      hive.site['hive.zookeeper.session.timeout'] ?= '600000' # Default is "600000"
      hive.site['hive.server2.zookeeper.namespace'] ?= 'hiveserver2' # Default is "hiveserver2"

## Configuration for Proxy users

      hadoop_ctxs = @contexts ['ryba/hadoop/hdfs_nn','ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hive.user.name}.groups"] ?= '*'
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hive.user.name}.hosts"] ?= '*'
