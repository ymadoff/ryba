
# Sqoop

[Apache Sqoop](http://sqoop.apache.org/) is a tool designed for efficiently transferring bulk data between
Apache Hadoop and structured datastores such as relational databases.

      module.exports =
        use:
          java: implicit: true, module: 'masson/commons/java'
          mysql_client: 'masson/commons/mysql/client'
          hadoop_core: 'ryba/hadoop/core'
          hdfs_client: implicit: true, module: 'ryba/hadoop/hdfs_client'
          hive_client: implicit: true, module: 'ryba/hive/client'
          yarn_client: implicit: true, module: 'ryba/hadoop/yarn_client'
        configure:
          'ryba/sqoop/configure'
        commands:
          'install':
            'ryba/sqoop/install'
