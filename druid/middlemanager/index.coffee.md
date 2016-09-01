
# Druid MiddleManager Server

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports = ->
      'prepare':
        'ryba/druid/prepare'
      'configure':[
        'ryba/druid/configure'
        'ryba/druid/middlemanager/configure'
      ]
      'install': [
        'masson/commons/java'
        'ryba/hadoop/hdfs_client'
        'ryba/druid/middlemanager/install'
        'ryba/druid/middlemanager/start'
      ]
      'start':
        'ryba/druid/middlemanager/start'
      'status':
        'ryba/druid/middlemanager/status'
      'stop':
        'ryba/druid/middlemanager/stop'
