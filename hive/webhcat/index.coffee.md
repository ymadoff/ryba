
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
        'masson/core/krb5_client/wait'
        'ryba/hadoop/core' # Install SPNEGO keytab
        'ryba/commons/krb5_user'
        'ryba/hive/client'
        'ryba/pig'
        'ryba/sqoop'
        'ryba/lib/hconfigure'
        'ryba/lib/hdfs_upload'
        'ryba/lib/hdp_select'
        'ryba/hive/webhcat/install'
        'ryba/zookeeper/server/wait'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hive/hcatalog/wait'
        'ryba/hive/webhcat/start'
        'ryba/hive/webhcat/wait'
        'ryba/hive/webhcat/check'
      ]
      'start': [
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/wait'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hive/hcatalog/wait'
        'ryba/hive/webhcat/start'
      ]
      'status': [
        'ryba/hive/webhcat/status'
      ]
      'stop': [
        'ryba/hive/webhcat/stop'
      ]
      'wait': [
        'ryba/hive/webhcat/wait'
      ]
      
