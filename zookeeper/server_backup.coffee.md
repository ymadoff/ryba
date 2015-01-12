
# ZooKeeper Backup

The latest snapshot and the transaction log from the time of the snapshot is
enough to recover to current state. To provide additionnal garanties, the
default configuration backup the last 3 snapshots(in case of corruption of the
latest snap) and the transaction logs from the timestamp corresponding to the
earliest snapshot.

Execute `./bin/ryba backup -m ryba/zookeper/server` to run this module.

    module.exports = []
    module.exports.push require('./server').configure

## Compress the data directory

ZooKeeper stores its data in a data directory and its transaction log in a
transaction log directory. By default these two directories are the same.

TODO: Add the backup facility

    module.exports.push name: "ZooKeeper Server # Purge Transaction Logs", callback: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      now = Math.floor Date.now() / 1000
      ctx.execute [
        cmd: """
        tar czf /var/tmp/ryba-zookeeper-data-#{now}.tgz -C #{zookeeper.config.dataDir} .
        """
      ,
        cmd: """
        tar czf /var/tmp/ryba-zookeeper-log-#{now}.tgz -C #{zookeeper.config.dataLogDir} .
        """
        if: zookeeper.config.dataLogDir
      ], next

## Purge Transaction Logs

A ZooKeeper server will not remove old snapshots and log files when using the
default configuration (see autopurge below), this is the responsibility of the
operator.

The PurgeTxnLog utility implements a simple retention policy that administrators
can use. Its expected arguments are "dataLogDir [snapDir] -n count".

Note, Automatic purging of the snapshots and corresponding transaction logs was
introduced in version 3.4.0 and can be enabled via the following configuration
parameters autopurge.snapRetainCount and autopurge.purgeInterval.

    module.exports.push name: "ZooKeeper Server # Purge Transaction Logs", callback: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      ctx.execute
        cmd: """
        java -cp zookeeper.jar:lib/slf4j-api-1.6.1.jar:lib/slf4j-log4j12-1.6.1.jar:lib/log4j-1.2.15.jar:conf \
          org.apache.zookeeper.server.PurgeTxnLog \
          #{zookeeper.config.dataLogDir or ''} #{zookeeper.config.dataDir} -n #{zookeeper.retention}
        """
      , next

## Resources

*   [ZooKeeper Data File Management][data_file]
*   [ZooKeeper Maintenance][maintenance]
*   [Cloudera recommandations][cloudera]

[data_file]: http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_dataFileManagement
[maintenance]: http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_maintenance
[cloudera]: http://www.cloudera.com/content/cloudera/en/documentation/cdh4/latest/CDH4-Installation-Guide/cdh4ig_topic_21_4.html

