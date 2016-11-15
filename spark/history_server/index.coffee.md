# Spark History Server

    module.exports =
      use:
        'java': implicit: true, module: 'masson/commons/java'
        'hdfs': 'ryba/hadoop/hdfs_client'
        'hive': 'ryba/hive/client'
      configure:
        'ryba/spark/history_server/configure'
      commands:
        'install': [
          'ryba/spark/history_server/install'
          'ryba/spark/history_server/start'
          'ryba/spark/history_server/check'
        ]
        'start':
          'ryba/spark/history_server/start'
        'stop':
          'ryba/spark/history_server/stop'
        'start':
          'ryba/spark/history_server/check'
