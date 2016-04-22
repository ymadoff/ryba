
# WebHCat
[WebHCat](https://cwiki.apache.org/confluence/display/Hive/WebHCat) is a REST API for HCatalog. (REST stands for "representational state transfer", a style of API based on HTTP verbs).  The original name of WebHCat was Templeton.

    module.exports = ->
      'configure': [
        'ryba/hadoop/core'
        'ryba/hive/hcatalog'
        'ryba/hive/webhcat/configure'
      ]
      'install': [
        'masson/core/iptables'
        'ryba/hadoop/core' # Install SPNEGO keytab
        'ryba/commons/krb5_user'
        'ryba/hive/client'
        'ryba/pig'
        'ryba/sqoop'
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
      
