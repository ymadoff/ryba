
# Hadoop HDFS DataNode

A [DataNode](http://wiki.apache.org/hadoop/DataNode) manages the storage attached to the node it run on. There are usually
one DataNode per node in the cluster. HDFS exposes a file system namespace and
allows user data to be stored in files. Internally, a file is split into one or
more blocks and these blocks are stored in a set of DataNodes. The DataNodes
also perform block creation, deletion, and replication upon instruction from the
NameNode.

To provide a fast failover in a Higth Availabity (HA) enrironment, it is
necessary that the Standby node have up-to-date information regarding the
location of blocks in the cluster. In order to achieve this, the DataNodes are
configured with the location of both NameNodes, and send block location
information and heartbeats to both.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        zoo_server: module: 'ryba/zookeeper/server'
      configure:
        'ryba/hadoop/hdfs_dn/configure'
      commands:
        'check':
          'ryba/hadoop/hdfs_dn/check'
        'install': [
          'ryba/hadoop/hdfs_dn/install'
          'ryba/hadoop/hdfs_dn/start'
          'ryba/hadoop/hdfs_dn/check'
        ]
        'start':
          'ryba/hadoop/hdfs_dn/start'
        'status':
          'ryba/hadoop/hdfs_dn/status'
        'stop':
          'ryba/hadoop/hdfs_dn/stop'
