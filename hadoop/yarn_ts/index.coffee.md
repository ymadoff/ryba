
# YARN Timeline Server

The [Yarn Timeline Server][ts] store and retrieve current as well as historic
information for the applications running inside YARN.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: 'ryba/hadoop/core'
        hdfs_client: 'ryba/hadoop/hdfs_client'
        # yarn_client: 'ryba/hadoop/yarn_client'
      configure:
        'ryba/hadoop/yarn_ts/configure'
      commands:
        'check':
          'ryba/hadoop/yarn_ts/check'
        'install': [
          'ryba/hadoop/yarn_ts/install'
          'ryba/hadoop/yarn_ts/start'
          'ryba/hadoop/yarn_ts/check'
        ]
        'start':
          'ryba/hadoop/yarn_ts/start'
        'stop':
          'ryba/hadoop/yarn_ts/stop'

[ts]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServer.html
