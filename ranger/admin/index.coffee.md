
# Ranger Policy Manager

Apache Ranger offers a centralized security framework to manage fine-grained
access control over Hadoop data access components like Apache Hive and Apache HBase.
HDfs top of decision
Ranger permit access


    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        mysql_client: implicit: true, module: 'masson/commons/mysql/client'
        hadoop_core: module: 'ryba/hadoop/core'
        solr_cloud_docker: module: 'ryba/solr/cloud_docker'
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
      configure:
        'ryba/ranger/admin/configure'
      commands:
        'install': [
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
