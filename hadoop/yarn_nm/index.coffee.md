
# YARN NodeManager

[The NodeManager](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.htm) (NM) is YARN’s per-node agent,
and takes care of the individual
computing nodes in a Hadoop cluster. This includes keeping up-to date with the
ResourceManager (RM), overseeing containers’ life-cycle management; monitoring
resource usage (memory, CPU) of individual containers, tracking node-health,
log’s management and auxiliary services which may be exploited by different YARN
applications.

    module.exports = ->
      # 'backup': 'ryba/hadoop/yarn_nm/backup'
      # 'check': 'ryba/hadoop/yarn_nm/check'
      'report': [
        'masson/bootstrap/report'
        'ryba/hadoop/yarn_nm/report'
      ]
      'check': [
        # 'ryba/hadoop/yarn_rm/wait'
        'ryba/hadoop/yarn_nm/check'
      ]
      'install': [
        'masson/core/iptables'
        'masson/core/info'
        'masson/core/krb5_client/wait'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hadoop/yarn_nm/install'
        'ryba/hadoop/yarn_nm/start'
        'ryba/hadoop/yarn_nm/check'
        'ryba/zookeeper/server/wait'
        'ryba/hadoop/yarn_nm/start'
      ]
      'start': [
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/wait'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hadoop/yarn_nm/start'
      ]
      'status': 'ryba/hadoop/yarn_nm/status'
      'stop': 'ryba/hadoop/yarn_nm/stop'
