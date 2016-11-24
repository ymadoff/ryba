
# YARN ResourceManager

[Yarn ResourceManager ](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html) is the central authority that manages resources and schedules applications running atop of YARN.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        # yarn_client: 'ryba/hadoop/yarn_client/install'
        zoo_server: 'ryba/zookeeper/server'
        mapred_jhs: 'ryba/hadoop/mapred_jhs'
        yarn_ts: 'ryba/hadoop/yarn_ts'
        ranger_admin: 'ryba/ranger/admin'
      configure: [
        'ryba/hadoop/yarn_rm/configure'
        'ryba/ranger/plugins/yarn/configure'
        ]
      commands:
        # 'backup': 'ryba/hadoop/yarn_rm/backup'
        'check':
          'ryba/hadoop/yarn_rm/check'
        'report': [
          'masson/bootstrap/report'
          'ryba/hadoop/yarn_rm/report'
        ]
        'install': [
          'ryba/hadoop/yarn_rm/install'
          'ryba/hadoop/yarn_rm/scheduler'
          'ryba/hadoop/yarn_rm/start'
          'ryba/hadoop/yarn_rm/check'
        ]
        'start':
          'ryba/hadoop/yarn_rm/start'
        'status':
          'ryba/hadoop/yarn_rm/status'
        'stop':
          'ryba/hadoop/yarn_rm/stop'


[restart]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html
[ml_root_acl]: http://lucene.472066.n3.nabble.com/Yarn-HA-Zookeeper-ACLs-td4138735.html
[cloudera_ha]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_rm_ha_config.html
[cloudera_wp]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_ha_yarn_work_preserving_recovery.html
[hdp_wp]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/bk_yarn_resource_mgt/content/ch_work-preserving_restart.html
[YARN-128]: https://issues.apache.org/jira/browse/YARN-128
[YARN-128-pdf]: https://issues.apache.org/jira/secure/attachment/12552867/RMRestartPhase1.pdf
[YARN-556]: https://issues.apache.org/jira/browse/YARN-556
[YARN-556-pdf]: https://issues.apache.org/jira/secure/attachment/12599562/Work%20Preserving%20RM%20Restart.pdf
