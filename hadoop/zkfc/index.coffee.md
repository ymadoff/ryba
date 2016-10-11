
# Hadoop ZKFC

The [ZKFailoverController (ZKFC)](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html) is a new component which is a ZooKeeper client which also monitors and manages the state of the NameNode.
 Each of the machines which runs a NameNode also runs a ZKFC, and that ZKFC is responsible for Health monitoring, ZooKeeper session management, ZooKeeper-based election.


    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        hadoop_core: 'ryba/hadoop/core'
        hdfs_nn: implicit: true, module: 'ryba/hadoop/hdfs_nn'
      configure:
        # 'ryba/hadoop/hdfs_nn/configure'
        'ryba/hadoop/zkfc/configure'
      commands:
        'check':
          'ryba/hadoop/zkfc/check'
        'install': [
          'ryba/hadoop/zkfc/install'
          'ryba/hadoop/zkfc/start'
          'ryba/hadoop/zkfc/check'
        ]
        'start':
          'ryba/hadoop/zkfc/start'
        'stop':
          'ryba/hadoop/zkfc/stop'
        'status':
          'ryba/hadoop/zkfc/status'
