
# YARN Client

The [Hadoop YARN Client](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/WebServicesIntro.html) web service REST APIs are a set of URI resources that give access to the cluster, nodes, applications, and application historical information.
The URI resources are grouped into APIs based on the type of information returned. Some URI resources return collections while others return singletons.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        hdfs_client: implicit: true, module: 'ryba/hadoop/hdfs_client'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        yarn_nm: 'ryba/hadoop/yarn_nm'
        yarn_ts: 'ryba/hadoop/yarn_ts'
        yc_ctxs: 'ryba/hadoop/yarn_client'
      configure:
        'ryba/hadoop/yarn_client/configure'
      commands:
        'check':
          'ryba/hadoop/yarn_client/check'
        'install': [
          'ryba/hadoop/yarn_client/install'
          'ryba/hadoop/yarn_client/check'
        ]
        'report': [
          'masson/bootstrap/report'
          'ryba/hadoop/yarn_client/report'
        ]
