
# Ranger Policy Manager

Apache Ranger offers a centralized security framework to manage fine-grained
access control over Hadoop data access components like Apache Hive and Apache HBase.
HDfs top of decision
Ranger permit access


    module.exports = ->
      'configure': [
        'ryba/commons/db_admin'
        'ryba/hadoop/core'
        'ryba/ranger/admin/configure'
      ]
      'install': [
          # to have hdp select installed
        'ryba/hadoop/core'
        'ryba/ranger/admin/install'
        'ryba/ranger/admin/start'
        'ryba/ranger/admin/setup'
      ]
      'start': [
        'ryba/ranger/admin/start'
      ]
      'stop': [
        'ryba/ranger/admin/stop'
      ]




