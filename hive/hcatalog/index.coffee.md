
# Hive Server

[HCatalog](https://cwiki.apache.org/confluence/display/Hive/HCatalog+UsingHCat) 
is a table and storage management layer for Hadoop that enables users with different 
data processing tools — Pig, MapReduce — to more easily read and write data on the grid.
 HCatalog’s table abstraction presents users with a relational view of data in the Hadoop
 distributed file system (HDFS) and ensures that users need not worry about where or in what
 format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        mapred_client: implicit: true, module: 'ryba/hadoop/mapred_client'
        postgres_server: 'masson/commons/postgres/server'
        mysql_server: 'masson/commons/mysql/server'
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
        zookeeper_server: 'ryba/zookeeper/server'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        yarn_nm: 'ryba/hadoop/yarn_nm'
        tez: 'ryba/tez'
        hbase_client: implicit: true, module: 'ryba/hbase/client'
      configure:
        'ryba/hive/hcatalog/configure'
      commands:
        'install': [
          'ryba/hive/hcatalog/install'
          'ryba/hive/hcatalog/start'
          'ryba/hive/hcatalog/check'
        ]
        'check': [
          'ryba/commons/db_admin'
          'ryba/hive/hcatalog/check'
        ]
        'start':
          'ryba/hive/hcatalog/start'
        'status':
          'ryba/hive/hcatalog/status'
        'stop':
          'ryba/hive/hcatalog/stop'
        'wait':
          'ryba/hive/hcatalog/wait'
        'report': [
          'masson/bootstrap/report'
          'ryba/hive/hcatalog/report'
        ]
        'backup':
          'ryba/hive/hcatalog/backup'
