
# Oozie Server

[Oozie Server][Oozie] is a server based Workflow Engine specialized in running workflow jobs.
Workflows are basically collections of actions.
These actions can be  Hadoop Map/Reduce jobs, Pig jobs arranged in a control dependency DAG (Direct Acyclic Graph).
Please check Oozie page

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        mysql_server: 'masson/commons/mysql/server'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
        yarn_client: implicit: true, module: 'ryba/hadoop/yarn_client'
        spark_client: implicit: true, module: 'ryba/spark/client'
      configure: 'ryba/oozie/server/configure'
      commands:
        'install': [
          'ryba/oozie/server/install'
          'ryba/oozie/server/start'
        ]
        'start':
          'ryba/oozie/server/start'
        'status':
          'ryba/oozie/server/status'
        'stop':
          'ryba/oozie/server/stop'
        'wait':
          'ryba/oozie/server/wait'
        'backup':
          'ryba/oozie/server/backup'

[Oozie]: https://oozie.apache.org/docs/3.1.3-incubating/index.html
