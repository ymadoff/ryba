
# ZooKeeper Backup

The latest snapshot and the transaction log from the time of the snapshot is
enough to recover to current state. To provide additionnal garanties, the
default configuration backup the last 3 snapshots(in case of corruption of the
latest snap) and the transaction logs from the timestamp corresponding to the
earliest snapshot.

Execute `./bin/ryba backup -m ryba/zookeeper/server` to run this module.

    module.exports = []
    module.exports.push require('./index').configure

## Compress the data directory

ZooKeeper stores its data in a data directory and its transaction log in a
transaction log directory. By default these two directories are the same.

TODO: Add the backup facility

    module.exports.push name: "ZooKeeper Server # Backup", handler: (ctx, next) ->
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

    module.exports.push name: "ZooKeeper Server # Purge Transaction Logs", handler: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      ctx.execute
        cmd: """
        java -cp /usr/hdp/current/zookeeper-server/zookeeper.jar:/usr/hdp/current/zookeeper-server/lib/*:/usr/hdp/current/zookeeper-server/conf \
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
