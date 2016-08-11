
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
        'ryba/druid/overlord/install'
        'ryba/druid/overlord/start'
      ]
      'start':
        'ryba/druid/overlord/start'
      'status':
        'ryba/druid/overlord/status'
      'stop':
        'ryba/druid/overlord/stop'
