
# Druid

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports = ->
      'prepare':
        'ryba/druid/prepare'
      'configure':
        'ryba/druid/configure'
      'install': [
        'masson/commons/java'
        'ryba/hadoop/hdfs_client'
        'ryba/druid/coordinator/install'
        'ryba/druid/coordinator/start'
      ]
      'start':
        'ryba/druid/coordinator/start'
      'status':
        'ryba/druid/coordinator/status'
      'stop':
        'ryba/druid/coordinator/stop'
