
# Oozie Client

Oozie is a server based Workflow Engine specialized in running workflow jobs
with actions that run Hadoop Map/Reduce and Pig jobs.

The Oozie server installation includes the Oozie client. The Oozie client should
be installed in remote machines only.

    module.exports = 
      use: 
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        hadoop_core: implicit: true, module: 'ryba/oozie/server'
        mapred_client: implicit: true, module: 'ryba/hadoop/mapred_client'
        oozie_server: 'ryba/hadoop/yarn_client'
      configure: 'ryba/oozie/client/configure'
      commands:
        'install': [
          'ryba/oozie/client/install'
          'ryba/oozie/client/check'
        ]
        'check':
          'ryba/oozie/client/check'
