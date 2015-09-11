
# Hive HCatalog Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hive/server2/wait'
    # module.exports.push require('./index').configure

## Check Thrift Port

Check if the Hive Server2 server is listening.

    module.exports.push name: 'Hive Server2 # Check Thrift Port', label_true: 'CHECKED', handler: ->
      {hive} = @config.ryba
      port = if hive.site['hive.server2.transport.mode'] is 'http'
      then hive.site['hive.server2.thrift.http.port']
      else hive.site['hive.server2.thrift.port']
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{port}"

    module.exports.push name: 'Hive Server2 # Check JDBC', handler: ->
      # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html
      # !connect jdbc:hive2://master3.ryba:10001/default;principal=hive/master3.ryba@HADOOP.RYBA
      @log? 'TODO: check hive server2 jdbc'
      # hive.site['hive.zookeeper.quorum']
      # jdbc:hive2://<zookeeper_ensemble>;serviceDiscoveryMode=zooKeeper; zooKeeperNamespace=<hiveserver2_namespace
