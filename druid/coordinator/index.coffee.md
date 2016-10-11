
# Druid Coordinator

The Druid [coordinator] node is primarily responsible for segment management and
distribution. More specifically, the Druid [coordinator] node communicates to
historical nodes to load or drop segments based on configurations. The Druid
[coordinator] is responsible for loading new segments, dropping outdated segments,
managing segment replication, and balancing segment load.

[coordinator]: http://druid.io/docs/latest/design/coordinator.html

    module.exports = ->
      'prepare':
        'ryba/druid/prepare'
      'configure':
        'ryba/druid/coordinator/configure'
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
