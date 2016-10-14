
# Hive HCatalog Check

    module.exports =  header: 'Hive Server2 Check Thrift', label_true: 'CHECKED', handler: (options) ->
      {hive} = @config.ryba            
      port = if hive.server2.site['hive.server2.transport.mode'] is 'http'
      then hive.server2.site['hive.server2.thrift.http.port']
      else hive.server2.site['hive.server2.thrift.port']

## Wait

      @call once: true, 'ryba/hive/server2/wait'

## Check Thrift Port

Check if the Hive Server2 server is listening.

      @execute
        label_true: 'CHECKED'
        header: 'Check Thrift Port'
        cmd: "echo > /dev/tcp/#{@config.host}/#{port}"

      @call header: 'Check JDBC', handler: ->
        # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html
        # !connect jdbc:hive2://master3.ryba:10001/default;principal=hive/master3.ryba@HADOOP.RYBA
        options.log? 'TODO: check hive server2 jdbc'
        # hive.server2.site['hive.zookeeper.quorum']
        # jdbc:hive2://<zookeeper_ensemble>;serviceDiscoveryMode=zooKeeper; zooKeeperNamespace=<hiveserver2_namespace
