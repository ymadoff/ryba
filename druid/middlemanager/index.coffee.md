
# Druid MiddleManager Server

The [middle manager] node is a worker node that executes submitted tasks. Middle Managers forward tasks to peons that run in separate JVMs. The reason we have separate JVMs for tasks is for resource and log isolation. Each Peon is capable of running only one task at a time, however, a middle manager may have multiple peons.

[Peons] run a single task in a single JVM. MiddleManager is responsible for creating Peons for running tasks. Peons should rarely (if ever for testing purposes) be run on their own.

[middle manager]: http://druid.io/docs/latest/design/middlemanager.html
[peons]: http://druid.io/docs/latest/design/peons.html

    module.exports = ->
      'prepare':
        'ryba/druid/prepare'
      'configure':
        'ryba/druid/middlemanager/configure'
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
