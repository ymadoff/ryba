
# Druid Coordinator

The Druid [coordinator] node is primarily responsible for segment management and
distribution. More specifically, the Druid [coordinator] node communicates to
historical nodes to load or drop segments based on configurations. The Druid
[coordinator] is responsible for loading new segments, dropping outdated segments,
managing segment replication, and balancing segment load.

[coordinator]: http://druid.io/docs/latest/design/coordinator.html

    module.exports =
      use:
        java: 'masson/commons/java'
        hdfs_client: 'ryba/hadoop/hdfs_client'
        druid_commons: implicit: true, module: 'ryba/druid'
        druid_coordinator: 'ryba/druid/coordinator'
      configure:
        'ryba/druid/coordinator/configure'
      commands:
        'prepare':
          'ryba/druid/prepare'
        'install': [
          'ryba/druid/coordinator/install'
          'ryba/druid/coordinator/start'
        ]
        'start':
          'ryba/druid/coordinator/start'
        'status':
          'ryba/druid/coordinator/status'
        'stop':
          'ryba/druid/coordinator/stop'
