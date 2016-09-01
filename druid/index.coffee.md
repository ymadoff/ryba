
# Druid

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports = ->
      'prepare':
        'ryba/druid/prepare'
      'configure': [
        'ryba/commons/db_admin'
        'ryba/druid/configure'
      ]
      'install': [
        'masson/commons/java'
        'ryba/hadoop/hdfs_client'
        'ryba/druid/install'
        # 'ryba/druid/start'
      ]
      # 'start':
      #   'ryba/druid/start'
      # 'status':
      #   'ryba/druid/status'
      # 'stop':
      #   'ryba/druid/stop'
