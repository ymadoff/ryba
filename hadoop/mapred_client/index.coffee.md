
# MapReduce Client

MapReduce is the key algorithm that the Hadoop MapReduce engine uses to distribute work around a cluster.
The key aspect of the MapReduce algorithm is that if every Map and Reduce is independent of all other ongoing Maps and Reduces,
then the operation can be run in parallel on different keys and lists of data. On a large cluster of machines, you can go one step further, and run the Map operations on servers where the data lives.
Rather than copy the data over the network to the program, you push out the program to the machines.
The output list can then be saved to the distributed filesystem, and the reducers run to merge the results. Again, it may be possible to run these in parallel, each reducing different keys.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: 'ryba/hadoop/core'
        yarn_client: implicit: true, module: 'ryba/hadoop/yarn_client'
        hdfs_client: implicit: true, module: 'ryba/hadoop/hdfs_client'
        hfds_dn: 'ryba/hadoop/hdfs_dn'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        mapred_jhs: 'ryba/hadoop/mapred_jhs'
      configure:
        'ryba/hadoop/mapred_client/configure'
      commands:
        'check':
          'ryba/hadoop/mapred_client/check'
        'report': [
          'masson/bootstrap/report'
          'ryba/hadoop/mapred_client/report'
        ]
        'install': [
          'ryba/hadoop/mapred_client/install'
          'ryba/hadoop/mapred_client/check'
        ]
