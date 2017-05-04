
# Tez

[Apache Tez][tez] is aimed at building an application framework which allows for
a complex directed-acyclic-graph of tasks for processing data. It is currently
built atop Apache Hadoop YARN.

## Commands

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        http: 'masson/commons/httpd'
        hadoop_core: 'ryba/hadoop/core/configure'
        hdfs_client: implicit: true, module: 'ryba/hadoop/hdfs_client'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        yarn_ts: 'ryba/hadoop/yarn_ts'
        yarn_nm: 'ryba/hadoop/yarn_nm'
        yarn_client: implicit: true, module: 'ryba/hadoop/yarn_client'
      configure:
        'ryba/tez/configure'
      commands:
        'install': [
          'ryba/tez/install'
          'ryba/tez/check'
        ]
        'check':
          'ryba/tez/check'

[tez]: http://tez.apache.org/
[instructions]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.8.4)
