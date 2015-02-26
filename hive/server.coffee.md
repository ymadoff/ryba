
# Hive Server

    module.exports = []

## Configure

Note, the following properties are required by knox in secured mode:

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
      "server2_opts": "-Xmx4096m"
      "site": {
        "javax.jdo.option.ConnectionURL": "jdbc:mysql://front1.hadoop:3306/hive?createDatabaseIfNotExist=true"
        "javax.jdo.option.ConnectionDriverName": "com.mysql.jdbc.Driver"
        "javax.jdo.option.ConnectionUserName": "hive"
        "javax.jdo.option.ConnectionPassword": "hive123"
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/commons/mysql_server').configure ctx
      require('./_').configure ctx
      {hive, db_admin, static_host, realm} = ctx.config.ryba
      # Layout
      hive.log_dir ?= '/var/log/hive'
      hive.pid_dir ?= '/var/run/hive'
      # Environment
      hive.hcatalog_opts ?= ''
      hive.server2_opts ?= ''
      # Configuration
      hive.site ?= {}
      unless hive.site['hive.metastore.uris']
        hive.site['hive.metastore.uris'] = []
        for host in ctx.hosts_with_module 'ryba/hive/server'
          hive.site['hive.metastore.uris'].push "thrift://#{host}:9083"
        hive.site['hive.metastore.uris'] = hive.site['hive.metastore.uris'].join ','
      hive.site['datanucleus.autoCreateTables'] ?= 'true'
      hive.site['hive.security.authorization.enabled'] ?= 'true'
      hive.site['hive.security.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive.site['hive.security.metastore.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive.site['hive.security.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.ProxyUserAuthenticator'
      hive.site['hive.server2.enable.doAs'] ?= 'true'
      hive.site['hive.server2.allow.user.substitution'] ?= 'true'
      hive.site['hive.server2.transport.mode'] ?= 'binary' # Kerberos not working with "http", see https://issues.apache.org/jira/browse/HIVE-6697
      hive.site['hive.server2.thrift.port'] ?= '10001'
      hive.site['hive.server2.thrift.http.port'] ?= '10001'
      hive.site['hive.server2.thrift.http.path'] ?= 'cliservice'
      hive.libs ?= []

## Configure Database

Note, at the moment, only MySQL is supported.

      if hive.site['javax.jdo.option.ConnectionURL']
        # Ensure the url host is the same as the one configured in config.ryba.db_admin
        {engine, hostname, port} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
        switch engine
          when 'mysql'
            throw new Error "Invalid host configuration" if hostname isnt db_admin.host and port isnt db_admin.port
          else throw new Error 'Unsupported database engine'
      else
        switch db_admin.engine
          when 'mysql'
            hive.site['javax.jdo.option.ConnectionURL'] ?= "jdbc:mysql://#{db_admin.host}:#{db_admin.port}/hive?createDatabaseIfNotExist=true"
          else throw new Error 'Unsupported database engine'
      throw new Error "Hive database username is required" unless hive.site['javax.jdo.option.ConnectionUserName']
      throw new Error "Hive database password is required" unless hive.site['javax.jdo.option.ConnectionPassword']

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
      # 'hive.server2.authentication.kerberos.principal': "hcat/#{ctx.config.host}@#{realm}"
      hive.site['hive.server2.authentication.kerberos.principal'] ?= "hive/#{static_host}@#{realm}"

## Configure Transactions and Lock Manager

With the addition of transactions in Hive 0.13 it is now possible to provide
full ACID semantics at the row level, so that one application can add rows while
another reads from the same partition without interfering with each other.

      hive.site['hive.support.concurrency'] ?= 'true' # Required, default to false
      hive.site['hive.enforce.bucketing'] ?= 'true' # Required, default to false
      hive.site['hive.exec.dynamic.partition.mode'] ?= 'nonstrict' # Required, default to strict
      # hive.site['hive.txn.manager'] ?= 'org.apache.hadoop.hive.ql.lockmgr.DummyTxnManager'
      hive.site['hive.txn.manager'] ?= 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager'
      hive.site['hive.txn.timeout'] ?= '300'
      hive.site['hive.txn.max.open.batch'] ?= '1000'
      hive.site['hive.compactor.initiator.on'] ?= 'true' # Required
      hive.site['hive.compactor.worker.threads'] ?= '1' # Required > 0
      hive.site['hive.compactor.worker.timeout'] ?= '86400'
      hive.site['hive.compactor.cleaner.run.interval'] ?= '5000'
      hive.site['hive.compactor.check.interval'] ?= '300'
      hive.site['hive.compactor.delta.num.threshold'] ?= '10'
      hive.site['hive.compactor.delta.pct.threshold'] ?= '0.1'
      hive.site['hive.compactor.abortedtxn.threshold'] ?= '1000'

## Configure HA

*   [Cloudera "Table Lock Manager" for Server2][ha_cdh5].
*   [Hortonworks Hive HA for HDP2.2][ha_hdp_2.2]
*   [Support dynamic service discovery for HiveServer2][HIVE-7935]

The [new Lock Manager][lock_mgr] introduced in Hive 0.13.0 shall accept
connections from multiple Server2 by introducing [transactions][[trnx].

The [MemoryTokenStore] is used if there is only one HCatalog Server otherwise we
default to the [DBTokenStore]. Also worth of interest is the
[ZooKeeperTokenStore].

      server_ctxs = ctx.contexts modules: 'ryba/hive/server'
      hive.site['hive.cluster.delegation.token.store.class'] ?= if server_ctxs.length > 1
      # then 'org.apache.hadoop.hive.thrift.ZooKeeperTokenStore'
      then 'org.apache.hadoop.hive.thrift.DBTokenStore'
      else 'org.apache.hadoop.hive.thrift.MemoryTokenStore'
      # CDH instructions:
      # hive.support.concurrency = 'true' # Required, default to false
      # hive.zookeeper.quorum = list of zookeeper address

## Commands

    module.exports.push commands: 'backup', modules: 'ryba/hive/server_backup'

    module.exports.push commands: 'check', modules: 'ryba/hive/server_check'

    module.exports.push commands: 'report', modules: 'ryba/hive/server_report'

    module.exports.push commands: 'install', modules: [
      'ryba/hive/server_install'
      'ryba/hive/server_start'
      'ryba/hive/server_wait'
      'ryba/hive/server_check'
    ]

    module.exports.push commands: 'start', modules: [
      'ryba/hive/server_start'
      'ryba/hive/server_wait'
    ]

    # module.exports.push commands: 'status', modules: 'ryba/hive/server_status'

    module.exports.push commands: 'stop', modules: 'ryba/hive/server_stop'

# Module Dependencies

    parse_jdbc = require '../lib/parse_jdbc'

[HIVE-7935]: https://issues.apache.org/jira/browse/HIVE-7935
[ha_hdp_2.2]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/Hadoop_HA_v22/ha_hive_metastore/index.html#Item1.1.2
[ha_cdh5]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_ha_hivemetastore.html#concept_jqx_zqk_dq_unique_1
[trnx]: https://cwiki.apache.org/confluence/display/Hive/Hive+Transactions#HiveTransactions-LockManager
[lock_mgr]: https://cwiki.apache.org/confluence/display/Hive/Hive+Transactions#HiveTransactions-LockManager
[MemoryTokenStore]: https://github.com/apache/hive/blob/trunk/shims/common/src/main/java/org/apache/hadoop/hive/thrift/MemoryTokenStore.java
[DBTokenStore]: https://github.com/apache/hive/blob/trunk/shims/common/src/main/java/org/apache/hadoop/hive/thrift/DBTokenStore.java
[ZooKeeperTokenStore]: https://github.com/apache/hive/blob/trunk/shims/common/src/main/java/org/apache/hadoop/hive/thrift/ZooKeeperTokenStore.java
