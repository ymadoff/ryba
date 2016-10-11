
# Druid Historical Server

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports = ->
      'prepare':
        'ryba/druid/prepare'
      'configure':
        'ryba/druid/historical/configure'
      'install': [
        'masson/commons/java'
        'ryba/hadoop/hdfs_client'
        'ryba/druid/historical/install'
        'ryba/druid/historical/start'
      ]
      'start':
        'ryba/druid/historical/start'
      'status':
        'ryba/druid/historical/status'
      'stop':
        'ryba/druid/historical/stop'
