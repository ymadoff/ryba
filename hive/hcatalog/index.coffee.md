
# Hive Server
[HCatalog](https://cwiki.apache.org/confluence/display/Hive/HCatalog+UsingHCat) is a table and storage management layer for Hadoop that enables users with different data processing tools — Pig, MapReduce — to more easily read and write data on the grid. HCatalog’s table abstraction presents users with a relational view of data in the Hadoop distributed file system (HDFS) and ensures that users need not worry about where or in what format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

    module.exports = []

## Configure

Example:

```json
{
  "ryba": {
    "hive": {
      "hcatalog": {
        opts": "-Xmx4096m",
        heapsize": "1024"
      },
      "site": {
        "javax.jdo.option.ConnectionURL": "jdbc:mysql://front1.hadoop:3306/hive?createDatabaseIfNotExist=true",
        "javax.jdo.option.ConnectionDriverName": "com.mysql.jdbc.Driver",
        "javax.jdo.option.ConnectionUserName": "hive",
        "javax.jdo.option.ConnectionPassword": "hive123"
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/commons/mysql_server').configure ctx
      require('../index').configure ctx
      {hive, db_admin, static_host, realm} = ctx.config.ryba
      # Layout and environment
      hive.hcatalog ?= {}
      hive.hcatalog.log_dir ?= '/var/log/hive-hcatalog'
      hive.hcatalog.pid_dir ?= '/var/run/hive-hcatalog'
      hive.hcatalog.opts ?= ''
      hive.hcatalog.heapsize ?= 1024
      # Configuration
      hive.site ?= {}
      unless hive.site['hive.metastore.uris']
        hive.site['hive.metastore.uris'] = []
        for host in ctx.hosts_with_module 'ryba/hive/hcatalog'
          hive.site['hive.metastore.uris'].push "thrift://#{host}:9083"
        hive.site['hive.metastore.uris'] = hive.site['hive.metastore.uris'].join ','
      hive.site['datanucleus.autoCreateTables'] ?= 'true'
      hive.site['hive.security.authorization.enabled'] ?= 'true'
      hive.site['hive.security.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive.site['hive.security.metastore.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive.site['hive.security.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.ProxyUserAuthenticator'
      hive.libs ?= []

## Configure Database

Note, at the moment, only MySQL is supported.

      if hive.site['javax.jdo.option.ConnectionURL']
        # Ensure the url host is the same as the one configured in config.ryba.db_admin
        # console.log parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
        {engine, addresses, port} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
        switch engine
          when 'mysql'
            admin = addresses.filter (address) ->
              address.host is db_admin.host and address.port is db_admin.port
            throw new Error "Invalid host configuration" unless admin.length
          else throw new Error 'Unsupported database engine'
      else
        switch db_admin.engine
          when 'mysql'
            hive.site['javax.jdo.option.ConnectionURL'] ?= "jdbc:mysql://#{db_admin.host}:#{db_admin.port}/hive?createDatabaseIfNotExist=true"
          else throw new Error 'Unsupported database engine'
      throw new Error "Hive database username is required" unless hive.site['javax.jdo.option.ConnectionUserName']
      throw new Error "Hive database password is required" unless hive.site['javax.jdo.option.ConnectionPassword']

## Configure Transactions and Lock Manager

With the addition of transactions in Hive 0.13 it is now possible to provide
full ACID semantics at the row level, so that one application can add rows while
another reads from the same partition without interfering with each other.

      # Get ZooKeeper Quorum
      zoo_ctxs = ctx.contexts 'ryba/zookeeper/server', require('../../zookeeper/server').configure
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      # Enable Table Lock Manager
      # Accoring to [Cloudera](http://www.cloudera.com/content/cloudera/en/documentation/cdh4/v4-2-0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html),
      # enabling the Table Lock Manager without specifying a list of valid
      # Zookeeper quorum nodes will result in unpredictable behavior. Make sure
      # that both properties are properly configured.
      hive.site['hive.support.concurrency'] ?= 'true' # Required, default to false
      hive.site['hive.zookeeper.quorum'] ?= zookeeper_quorum.join ','
      hive.site['hive.enforce.bucketing'] ?= 'true' # Required, default to false,  set to true to support INSERT ... VALUES, UPDATE, and DELETE transactions
      hive.site['hive.exec.dynamic.partition.mode'] ?= 'nonstrict' # Required, default to strict
      # hive.site['hive.txn.manager'] ?= 'org.apache.hadoop.hive.ql.lockmgr.DummyTxnManager'
      hive.site['hive.txn.manager'] ?= 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager'
      hive.site['hive.txn.timeout'] ?= '300'
      hive.site['hive.txn.max.open.batch'] ?= '1000'
      hive.site['hive.compactor.initiator.on'] ?= 'true' # Required
      hive.site['hive.compactor.worker.threads'] ?= '1' # Required > 0
      hive.site['hive.compactor.worker.timeout'] ?= '86400L'
      hive.site['hive.compactor.cleaner.run.interval'] ?= '5000'
      hive.site['hive.compactor.check.interval'] ?= '300L'
      hive.site['hive.compactor.delta.num.threshold'] ?= '10'
      hive.site['hive.compactor.delta.pct.threshold'] ?= '0.1f'
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

      server_ctxs = ctx.contexts modules: 'ryba/hive/hcatalog'
      hive.site['hive.cluster.delegation.token.store.class'] ?= if server_ctxs.length > 1
      # then 'org.apache.hadoop.hive.thrift.ZooKeeperTokenStore'
      then 'org.apache.hadoop.hive.thrift.DBTokenStore'
      else 'org.apache.hadoop.hive.thrift.MemoryTokenStore'
      # hive.site['hive.cluster.delegation.token.store.class'] = 'org.apache.hadoop.hive.thrift.ZooKeeperTokenStore'
      # hive.site['hive.cluster.delegation.token.store.zookeeper.connectString'] ?= zookeeper_quorum.join ','
      # CDH instructions:
      # hive.support.concurrency = 'true' # Required, default to false
      # hive.zookeeper.quorum = list of zookeeper address

## Commands

    module.exports.push commands: 'backup', modules: 'ryba/hive/hcatalog/backup'

    module.exports.push commands: 'check', modules: 'ryba/hive/hcatalog/check'

    module.exports.push commands: 'report', modules: 'ryba/hive/hcatalog/report'

    module.exports.push commands: 'install', modules: [
      'ryba/hive/hcatalog/install'
      'ryba/hive/hcatalog/start'
      'ryba/hive/hcatalog/wait'
      'ryba/hive/hcatalog/check'
    ]

    module.exports.push commands: 'start', modules: [
      'ryba/hive/hcatalog/start'
      'ryba/hive/hcatalog/wait'
    ]

    module.exports.push commands: 'status', modules: 'ryba/hive/hcatalog/status'

    module.exports.push commands: 'stop', modules: 'ryba/hive/hcatalog/stop'

# Module Dependencies

    parse_jdbc = require '../../lib/parse_jdbc'

[HIVE-7935]: https://issues.apache.org/jira/browse/HIVE-7935
[ha_hdp_2.2]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/Hadoop_HA_v22/ha_hive_metastore/index.html#Item1.1.2
[ha_cdh5]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_ha_hivemetastore.html#concept_jqx_zqk_dq_unique_1
[trnx]: https://cwiki.apache.org/confluence/display/Hive/Hive+Transactions#HiveTransactions-LockManager
[lock_mgr]: https://cwiki.apache.org/confluence/display/Hive/Hive+Transactions#HiveTransactions-LockManager
[MemoryTokenStore]: https://github.com/apache/hive/blob/trunk/shims/common/src/main/java/org/apache/hadoop/hive/thrift/MemoryTokenStore.java
[DBTokenStore]: https://github.com/apache/hive/blob/trunk/shims/common/src/main/java/org/apache/hadoop/hive/thrift/DBTokenStore.java
[ZooKeeperTokenStore]: https://github.com/apache/hive/blob/trunk/shims/common/src/main/java/org/apache/hadoop/hive/thrift/ZooKeeperTokenStore.java
