
# Oozie Server
[Oozie Server][Oozie] is a server based Workflow Engine specialized in running workflow jobs.
Workflows are basically collections of actions.
These actions can be  Hadoop Map/Reduce jobs, Pig jobs arranged in a control dependency DAG (Direct Acyclic Graph).
Please check Oozie page

    module.exports = -> 
      'configure': [
        'ryba/hadoop/core'
        'ryba/commons/db_admin'
        'ryba/oozie/server/configure'
      ]
      'install': [
         'masson/core/iptables'
         'masson/commons/java'
         'masson/commons/mysql_client'
         'ryba/commons/krb5_user'
         'ryba/commons/db_admin'
         'ryba/hadoop/core'
         #'ryba/hadoop/hdfs' # SPNEGO need access to the principal HTTP/$HOST@$REALM's keytab
         'ryba/hadoop/hdfs_dn/wait' # Create directories inside HDFS
         'ryba/lib/hconfigure'
         'ryba/lib/hdp_select'
         'ryba/lib/hdfs_mkdir'
         'ryba/hadoop/yarn_client'
         'ryba/oozie/server/install'
         'masson/core/krb5_client/wait'
         'ryba/zookeeper/server/wait'
         'ryba/hadoop/hdfs_nn/wait'
         'ryba/hbase/master/wait'
         'ryba/hive/hcatalog/wait'
         'ryba/hive/server2/wait'
         'ryba/hive/webhcat/wait'
         'ryba/oozie/server/start'
      ]
      'start': [
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/wait'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hbase/master/wait'
        'ryba/hive/hcatalog/wait'
        'ryba/hive/server2/wait'
        'ryba/hive/webhcat/wait'
        'ryba/oozie/server/start'
      ]
      'status': [
        'ryba/oozie/server/status'
      ]
      'stop': [
        'ryba/oozie/server/stop'
      ]
      'wait': [
        'ryba/oozie/server/wait'
      ]
      'backup': [
        'ryba/oozie/server/backup'
      ]

[Oozie]: https://oozie.apache.org/docs/3.1.3-incubating/index.html
