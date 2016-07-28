
# Hive Server

[HCatalog](https://cwiki.apache.org/confluence/display/Hive/HCatalog+UsingHCat) 
is a table and storage management layer for Hadoop that enables users with different 
data processing tools — Pig, MapReduce — to more easily read and write data on the grid.
 HCatalog’s table abstraction presents users with a relational view of data in the Hadoop
 distributed file system (HDFS) and ensures that users need not worry about where or in what
 format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

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

    module.exports = handler: ->
      hive = @config.ryba.hive ?= {}
      {db_admin, realm} = @config.ryba

## Users and Groups

      hive.conf_dir ?= '/etc/hive/conf'
      # User
      hive.user ?= {}
      hive.user = name: hive.user if typeof hive.user is 'string'
      hive.user.name ?= 'hive'
      hive.user.system ?= true
      hive.user.groups ?= 'hadoop'
      hive.user.comment ?= 'Hive User'
      hive.user.home ?= '/var/lib/hive'
      hive.user.limits ?= {}
      hive.user.limits.nofile ?= 64000
      hive.user.limits.nproc ?= true
      # Group
      hive.group ?= {}
      hive.group = name: hive.group if typeof hive.group is 'string'
      hive.group.name ?= 'hive'
      hive.group.system ?= true
      hive.user.gid = hive.group.name


      # Layout and environment
      hive.hcatalog ?= {}
      hive.hcatalog.log_dir ?= '/var/log/hive-hcatalog'
      hive.hcatalog.pid_dir ?= '/var/run/hive-hcatalog'
      hive.hcatalog.opts ?= ''
      hive.hcatalog.heapsize ?= 1024
      hive.libs ?= []
      hive.hcatalog.aux_jars ?= []
      aux_jars = ['/usr/hdp/current/hive-webhcat/share/hcatalog/hive-hcatalog-core.jar']
      for jar in aux_jars then hive.hcatalog.aux_jars.push jar unless jar in hive.hcatalog.aux_jars

## Environment

      hive.hcatalog.env ?=  {}
      #JMX Config
      hive.hcatalog.env["JMX_OPTS"] ?= ''
      if hive.hcatalog.env["JMXPORT"]? and hive.hcatalog.env["JMX_OPTS"].indexOf('-Dcom.sun.management.jmxremote.rmi.port') is -1
        hive.hcatalog.env["$JMXSSL"] ?= false
        hive.hcatalog.env["$JMXAUTH"] ?= false
        hive.hcatalog.env["JMX_OPTS"] += """
          -Dcom.sun.management.jmxremote \
          -Dcom.sun.management.jmxremote.authenticate=#{hive.hcatalog.env["$JMXAUTH"]} \
          -Dcom.sun.management.jmxremote.ssl=#{hive.hcatalog.env["$JMXSSL"]} \
          -Dcom.sun.management.jmxremote.port=#{hive.hcatalog.env["JMXPORT"]} \
          -Dcom.sun.management.jmxremote.rmi.port=#{hive.hcatalog.env["JMXPORT"]} \
          """
      hive.hcatalog.env.write ?= []
      hive.hcatalog.env.write.push {
        replace: """
        if [ "$SERVICE" = "metastore" ]; then
          export HADOOP_HEAPSIZE="#{hive.hcatalog.heapsize}"
          export HADOOP_CLIENT_OPTS="-Dhive.log.dir=#{hive.hcatalog.log_dir} #{hive.hcatalog.env.JMX_OPTS} -Xmx${HADOOP_HEAPSIZE}m #{hive.hcatalog.opts} $HADOOP_CLIENT_OPTS"
        fi
        """
        from: '# RYBA HIVE HCATALOG START'
        to: '# RYBA HIVE HCATALOG END'
        append: true
      }

# Configuration

      hive.site ?= {}
      # by default BONECP could lead to BLOCKED thread for class reading from DB
      hive.site['datanucleus.connectionPoolingType'] ?= 'DBCP'
      hive.site['hive.metastore.uris'] ?= null
      unless hive.site['hive.metastore.uris']
        hive.site['hive.metastore.uris'] = []
        for host in @contexts('ryba/hive/hcatalog').map( (ctx) -> ctx.config.host)
          hive.site['hive.metastore.uris'].push "thrift://#{host}:9083"
        hive.site['hive.metastore.uris'] = hive.site['hive.metastore.uris'].join ','
      hive.site['datanucleus.autoCreateTables'] ?= 'true'
      hive.site['hive.security.authorization.enabled'] ?= 'true'
      hive.site['hive.security.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive.site['hive.security.metastore.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      hive.site['hive.security.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.ProxyUserAuthenticator'
      # see https://cwiki.apache.org/confluence/display/Hive/WebHCat+InstallWebHCat
      hive.site['hive.security.metastore.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.HadoopDefaultMetastoreAuthenticator'
      hive.site['hive.metastore.pre.event.listeners'] ?= 'org.apache.hadoop.hive.ql.security.authorization.AuthorizationPreEventListener'
      hive.site['hive.metastore.cache.pinobjtypes'] ?= 'Table,Database,Type,FieldSchema,Order'

## Common Configuration

      # To prevent memory leak in unsecure mode, disable [file system caches](https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2)
      # , by setting following params to true
      hive.site['fs.hdfs.impl.disable.cache'] ?= 'false'
      hive.site['fs.file.impl.disable.cache'] ?= 'false'
      # TODO: encryption is only with Kerberos, need to check first
      # http://hortonworks.com/blog/encrypting-communication-between-hadoop-and-your-analytics-tools/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+hortonworks%2Ffeed+%28Hortonworks+on+Hadoop%29
      hive.site['hive.server2.thrift.sasl.qop'] ?= 'auth'
      # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm-chap14-2-3.html#rmp-chap14-2-3-5
      # If true, the metastore thrift interface will be secured with
      # SASL. Clients must authenticate with Kerberos.
      # Unset unvalid properties
      hive.site['hive.optimize.mapjoin.mapreduce'] ?= null
      hive.site['hive.heapsize'] ?= null
      hive.site['hive.auto.convert.sortmerge.join.noconditionaltask'] ?= null # "does not exist"
      hive.site['hive.exec.max.created.files'] ?= '100000' # "expects LONG type value"

## Kerberos

      hive.site['hive.metastore.sasl.enabled'] ?= 'true'
      # The path to the Kerberos Keytab file containing the metastore
      # thrift server's service principal.
      hive.site['hive.metastore.kerberos.keytab.file'] ?= '/etc/hive/conf/hive.service.keytab'
      # The service principal for the metastore thrift server. The
      # special string _HOST will be replaced automatically with the correct  hostname.
      hive.site['hive.metastore.kerberos.principal'] ?= "hive/_HOST@#{realm}"

## Configure Database

Note, at the moment, only MySQL and PostgreSQL are supported.
      
      hive.hcatalog.engine ?= 'postgresql'
      if hive.site['javax.jdo.option.ConnectionURL']
        # Ensure the url host is the same as the one configured in config.ryba.db_admin
        {engine, addresses, port} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
        switch engine
          when 'mysql'
            admin = addresses.filter (address) ->
              address.host is db_admin.mysql.host and "#{address.port}" is "#{db_admin.mysql.port}"
            throw new Error "Invalid host configuration" unless admin.length
          when 'postgresql'
            admin = addresses.filter (address) ->
              address.host is db_admin.postgres.host and"#{address.port}" is "#{db_admin.postgres.port}"
            throw new Error "Invalid host configuration" unless admin.length
          else throw new Error 'Unsupported database engine'
      else
        # do not base the default engine on db_admin, but on hive property.
        switch hive.hcatalog.engine
          when 'mysql'
            hive.site['javax.jdo.option.ConnectionURL'] ?= "jdbc:mysql://#{db_admin.mysql.host}:#{db_admin.mysql.port}/hive?createDatabaseIfNotExist=true"
            hive.site['javax.jdo.option.ConnectionDriverName'] ?= 'com.mysql.jdbc.Driver'
          when 'postgresql'
            hive.site['javax.jdo.option.ConnectionURL'] ?= "jdbc:postgresql://#{db_admin.postgres.host}:#{db_admin.postgres.port}/hive?createDatabaseIfNotExist=true"
            hive.site['javax.jdo.option.ConnectionDriverName'] ?= 'org.postgresql.Driver'
          else throw new Error 'Unsupported database engine'
      throw new Error "Hive database username is required" unless hive.site['javax.jdo.option.ConnectionUserName']
      throw new Error "Hive database password is required" unless hive.site['javax.jdo.option.ConnectionPassword']

## Configure Transactions and Lock Manager

With the addition of transactions in Hive 0.13 it is now possible to provide
full ACID semantics at the row level, so that one application can add rows while
another reads from the same partition without interfering with each other.

      # Get ZooKeeper Quorum
      zoo_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
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

hive.compactor.initiator.on can be activated on only one node !
[hive compactor initiator][initiator]
So we provide true by default on the 1st hive-hcatalog-server, but we force false elsewhere

      if @contexts('ryba/hive/hcatalog')[0].config.host is @config.host
        hive.site['hive.compactor.initiator.on'] ?= 'true'
      else
        hive.site['hive.compactor.initiator.on'] = 'false'
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

      server_ctxs = @contexts modules: 'ryba/hive/hcatalog'
      hive.site['hive.cluster.delegation.token.store.class'] ?= if server_ctxs.length > 1
      # then 'org.apache.hadoop.hive.thrift.ZooKeeperTokenStore'
      then 'org.apache.hadoop.hive.thrift.DBTokenStore'
      else 'org.apache.hadoop.hive.thrift.MemoryTokenStore'
      # hive.site['hive.cluster.delegation.token.store.class'] = 'org.apache.hadoop.hive.thrift.ZooKeeperTokenStore'
      # hive.site['hive.cluster.delegation.token.store.zookeeper.connectString'] ?= zookeeper_quorum.join ','
      # CDH instructions:
      # hive.support.concurrency = 'true' # Required, default to false
      # hive.zookeeper.quorum = list of zookeeper address

## Configuration for Proxy users

      hadoop_ctxs = @contexts ['ryba/hadoop/hdfs_nn','ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hive.user.name}.groups"] ?= '*'
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{hive.user.name}.hosts"] ?= '*'

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
[initiator]: https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties#ConfigurationProperties-hive.compactor.initiator.on
[hive-postgresql]: http://docs.hortonworks.com/HDPDocuments/Ambari-2.1.0.0/bk_ambari_reference_guide/content/_using_hive_with_postgresql.html
