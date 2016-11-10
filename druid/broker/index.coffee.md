
# Druid Broker Server

The [Broker] is the node to route queries to if you want to run a distributed 
cluster. It understands the metadata published to ZooKeeper about what segments 
exist on what nodes and routes queries such that they hit the right nodes. This 
node also merges the result sets from all of the individual nodes together. On 
start up, Realtime nodes announce themselves and the segments they are serving 
in Zookeeper. 

broker: http://druid.io/docs/latest/design/broker.html

    module.exports =
      use:
        java: 'masson/commons/java'
        hdfs_client: 'ryba/hadoop/hdfs_client'
        mapred_client: 'ryba/hadoop/mapred_client'
        druid_commons: implicit: true, module: 'ryba/druid'
        druid_overlord: 'ryba/druid/overlord'
        druid_broker: 'ryba/druid/broker'
      configure:
        'ryba/druid/broker/configure'
      commands:
        'check':
          'ryba/druid/broker/check'
        'prepare':
          'ryba/druid/prepare'
        'install': [
          'ryba/druid/broker/install'
          'ryba/druid/broker/start'
          'ryba/druid/broker/check'
        ]
        'start':
          'ryba/druid/broker/start'
        'status':
          'ryba/druid/broker/status'
        'stop':
          'ryba/druid/broker/stop'
