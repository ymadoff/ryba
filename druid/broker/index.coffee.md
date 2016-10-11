
# Druid Broker Server

The [Broker] is the node to route queries to if you want to run a distributed 
cluster. It understands the metadata published to ZooKeeper about what segments 
exist on what nodes and routes queries such that they hit the right nodes. This 
node also merges the result sets from all of the individual nodes together. On 
start up, Realtime nodes announce themselves and the segments they are serving 
in Zookeeper. 

broker: http://druid.io/docs/latest/design/broker.html

    module.exports = ->
      'check':
        'ryba/druid/broker/check'
      'prepare':
        'ryba/druid/prepare'
      'configure': [
        'ryba/commons/db_admin'
        'ryba/druid/broker/configure'
      ]
      'install': [
        'masson/commons/java'
        'ryba/hadoop/hdfs_client'
        'ryba/hadoop/mapred_client'
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
