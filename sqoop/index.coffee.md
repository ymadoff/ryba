
# Sqoop

[Apache Sqoop](http://sqoop.apache.org/) is a tool designed for efficiently transferring bulk data between
Apache Hadoop and structured datastores such as relational databases.

      module.exports = ->
        'configure': [
          'ryba/sqoop/configure'
        ]
        'install': [
          'masson/commons/mysql_client'
          'ryba/hadoop/hdfs_client/install'
          'ryba/hadoop/yarn_client/install'
          'ryba/lib/hconfigure'
          'ryba/lib/hdp_select'
          'ryba/sqoop/install'
        ]
