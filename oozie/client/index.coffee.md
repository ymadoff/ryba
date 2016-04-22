
# Oozie Client

Oozie is a server based Workflow Engine specialized in running workflow jobs
with actions that run Hadoop Map/Reduce and Pig jobs.

The Oozie server installation includes the Oozie client. The Oozie client should
be installed in remote machines only.

    module.exports = ->
      'configure': [
        'ryba/hadoop/core'
        'ryba/oozie/client/configure'
      ]
      'install': [
        'masson/commons/java'
        'ryba/hadoop/core'
        'ryba/hadoop/mapred_client'
        'ryba/hadoop/yarn_client'
        'ryba/oozie/client/install'
        'ryba/oozie/client/check'
      ]
      'check':
        'ryba/oozie/client/check'

  
