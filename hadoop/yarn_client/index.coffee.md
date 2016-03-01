
# YARN Client

The [Hadoop YARN Client](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/WebServicesIntro.html) web service REST APIs are a set of URI resources that give access to the cluster, nodes, applications, and application historical information.
The URI resources are grouped into APIs based on the type of information returned. Some URI resources return collections while others return singletons.

    module.exports = ->
      'check': [
        'ryba/hadoop/yarn_ts/wait'
        'ryba/hadoop/yarn_rm/wait'
        'ryba/hadoop/yarn_client/check'
      ]
      'configure': [
        'ryba/hadoop/hdfs_client'
        'ryba/hadoop/yarn_client/configure'
      ]
      'install': [
        'ryba/hadoop/core'
        'ryba/hadoop/yarn_client/install'
        'ryba/hadoop/yarn_client/check'
      ]
      'report': [
        'masson/bootstrap/report'
        'ryba/hadoop/yarn_client/report'
      ]
