
# WebHCat
[WebHCat](https://cwiki.apache.org/confluence/display/Hive/WebHCat) is a REST API for HCatalog. (REST stands for "representational state transfer", a style of API based on HTTP verbs).  The original name of WebHCat was Templeton.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        hadoop_core: 'ryba/hadoop/core'
        hive_client: 'ryba/hive/client'
        hive_hcatalog: 'ryba/hive/hcatalog'
        sqoop: 'ryba/sqoop'
        db_admin: 'ryba/commons/db_admin'
      configure:
        'ryba/hive/webhcat/configure'
      commands:
        'install': [
          'ryba/hive/webhcat/install'
          'ryba/hive/webhcat/start'
          'ryba/hive/webhcat/check'
        ]
        'start':
          'ryba/hive/webhcat/start'
        'status':
          'ryba/hive/webhcat/status'
        'stop':
          'ryba/hive/webhcat/stop'
        'wait':
          'ryba/hive/webhcat/wait'
