
# Druid Historical Server

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports =
      use:
        java: 'masson/commons/java'
        hdfs_client: 'ryba/hadoop/hdfs_client'
      configure:
        'ryba/druid/historical/configure'
      commands:
        'prepare':
          'ryba/druid/prepare'
        'install': [
          'ryba/druid/historical/install'
          'ryba/druid/historical/start'
        ]
        'start':
          'ryba/druid/historical/start'
        'status':
          'ryba/druid/historical/status'
        'stop':
          'ryba/druid/historical/stop'
