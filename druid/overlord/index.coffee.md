
# Druid Overlord

[Overlord] component manages task distribution to middle managers.

The [overlord] node is responsible for accepting tasks, coordinating task 
distribution, creating locks around tasks, and returning statuses to callers. 
[Overlord] can be configured to run in one of two modes - local or remote (local 
being default). In remote mode, the overlord and middle manager are run in 
separate processes and you can run each on a different server.

[overlord]: http://druid.io/docs/latest/design/indexing-service.html

    module.exports =
      use:
        java: 'masson/commons/java'
        hdfs_client: 'ryba/hadoop/hdfs_client'
        druid_commons: implicit: true, module: 'ryba/druid'
      configure:
        'ryba/druid/overlord/configure'
      commands:
        'prepare':
          'ryba/druid/prepare'
        'install': [
          'ryba/druid/overlord/install'
          'ryba/druid/overlord/start'
        ]
        'start':
          'ryba/druid/overlord/start'
        'status':
          'ryba/druid/overlord/status'
        'stop':
          'ryba/druid/overlord/stop'
