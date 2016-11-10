
# Druid MiddleManager Server

The [middle manager] node is a worker node that executes submitted tasks. Middle Managers forward tasks to peons that run in separate JVMs. The reason we have separate JVMs for tasks is for resource and log isolation. Each Peon is capable of running only one task at a time, however, a middle manager may have multiple peons.

[Peons] run a single task in a single JVM. MiddleManager is responsible for creating Peons for running tasks. Peons should rarely (if ever for testing purposes) be run on their own.

[middle manager]: http://druid.io/docs/latest/design/middlemanager.html
[peons]: http://druid.io/docs/latest/design/peons.html

    module.exports =
      use:
        java: 'masson/commons/java'
        hdfs_client: 'ryba/hadoop/hdfs_client'
        mapred_client: 'ryba/hadoop/mapred_client'
        druid_commons: implicit: true, module: 'ryba/druid'
      configure:
        'ryba/druid/middlemanager/configure'
      commands:
        'prepare':
          'ryba/druid/prepare'
        'install': [
          'ryba/druid/middlemanager/install'
          'ryba/druid/middlemanager/start'
        ]
        'start':
          'ryba/druid/middlemanager/start'
        'status':
          'ryba/druid/middlemanager/status'
        'stop':
          'ryba/druid/middlemanager/stop'
