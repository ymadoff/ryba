
# Hive Server

[HCatalog](https://cwiki.apache.org/confluence/display/Hive/HCatalog+UsingHCat) 
is a table and storage management layer for Hadoop that enables users with different 
data processing tools — Pig, MapReduce — to more easily read and write data on the grid.
 HCatalog’s table abstraction presents users with a relational view of data in the Hadoop
 distributed file system (HDFS) and ensures that users need not worry about where or in what
 format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

    module.exports = ->
      'configure': [
        'ryba/commons/db_admin'
        'ryba/hive/hcatalog/configure'
      ]
      'install': [
          'masson/core/krb5_client'
          'masson/core/iptables'
          'masson/commons/java'
          'masson/commons/mysql_client'
          'ryba/commons/krb5_user'
          'ryba/commons/db_admin'
          'ryba/hadoop/mapred_client/install'
          'ryba/tez'
          'ryba/hadoop/hdfs_dn/wait'
          'ryba/hbase/client'
          'ryba/lib/hconfigure'
          'ryba/lib/hdfs_upload'
          'ryba/lib/hdp_select'
          'ryba/hive/hcatalog/install'
          'ryba/hadoop/hdfs_nn/wait'
          'ryba/zookeeper/server/wait'
          'masson/core/krb5_client/wait'
          'ryba/hive/hcatalog/start'
          'ryba/hive/hcatalog/wait'
          'ryba/hive/hcatalog/check'
      ]
      'start': [
          'masson/core/krb5_client/wait'
          'ryba/hadoop/hdfs_nn/wait'
          'ryba/zookeeper/server/wait'
          'ryba/hive/hcatalog/start'
      ]
      'check': [
          'ryba/commons/db_admin'
          'ryba/hive/hcatalog/wait'
          'ryba/hive/hcatalog/check'
      ]
      'status': [
          'ryba/hive/hcatalog/status'
      ]
      'stop': [
          'ryba/hive/hcatalog/stop'
      ]
      'wait': [
          'ryba/hive/hcatalog/wait'
      ]
      'report': [
          'masson/bootstrap/report'
          'ryba/hive/hcatalog/wait'
          'ryba/hive/hcatalog/report'
      ]
      'backup': [
          'ryba/hive/hcatalog/backup'
      ]
