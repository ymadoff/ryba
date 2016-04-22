
# YARN Timeline Server

The [Yarn Timeline Server][ts] store and retrieve current as well as historic
information for the applications running inside YARN.

    module.exports = ->
      'check':
        'ryba/hadoop/yarn_ts/check'
      'configure': [
        'ryba/hadoop/core'
        'ryba/hadoop/yarn_client'
        'ryba/hadoop/yarn_ts/configure'
      ]
      'install': [
        'ryba/hadoop/hdfs_client'
        'ryba/hadoop/yarn_ts/install'
        'ryba/hadoop/yarn_ts/start'
        'ryba/hadoop/yarn_ts/check'
      ]
      'start':
        'ryba/hadoop/yarn_ts/start'
      'stop':
        'ryba/hadoop/yarn_ts/stop'

[ts]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServer.html
