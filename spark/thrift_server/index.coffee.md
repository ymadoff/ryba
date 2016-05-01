
# Spark SQL Thrift Server

Spark SQL is a Spark module for structured data processing. 
Unlike the basic Spark RDD API, the interfaces provided by Spark SQL provide Spark 
with more information about the structure of both the data and the computation being performed. 
It starts a custom instance of hive-sever2 and enabled user to register spark based table
in order to make the data accessible to hive clients.

    module.exports = ->
      'configure' : [
        'ryba/hadoop/core'
        'ryba/spark/thrift_server/configure'
      ]
      'install': [
        'masson/commons/java'
        'ryba/hadoop/hdfs_client'
        'ryba/spark/thrift_server/install'
        'ryba/spark/thrift_server/start'
        'ryba/spark/thrift_server/check'
      ]
      'check': [
        'ryba/spark/thrift_server/check'
      ]
      'stop': [
        'ryba/spark/thrift_server/stop'
      ]
      'start': [
        'ryba/spark/thrift_server/start'
      ]
