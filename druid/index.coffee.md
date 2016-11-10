
# Druid

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        hdfs_client:  implicit: true, module: 'ryba/hadoop/hdfs_client'
        yarn_client:  implicit: true, module: 'ryba/hadoop/yarn_client'
        mapred_client:  implicit: true, module: 'ryba/hadoop/mapred_client'
        postgres_server: 'masson/commons/postgres/server'
        mysql_server: 'masson/commons/mysql/server'
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
      configure:
        'ryba/druid/configure'
      commands:
        'prepare':
          'ryba/druid/prepare'
        'install':
          'ryba/druid/install'
