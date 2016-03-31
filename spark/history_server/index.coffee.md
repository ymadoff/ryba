# Spark History Server

    module.exports = ->
      'configure' : [
        'ryba/hadoop/core/configure'
        'ryba/spark/history_server/configure'
      ]
      'install': [
        'masson/commons/java'
        'ryba/hadoop/core'
        'ryba/hadoop/hdfs_client'
        'ryba/hive/client'
        'ryba/spark/history_server/install'
      ]
