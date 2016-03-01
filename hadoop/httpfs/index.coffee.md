
# HDFS HttpFS

HttpFS is a server that provides a REST HTTP gateway supporting all HDFS File
System operations (read and write). And it is inteoperable with the webhdfs REST
HTTP API.

    module.exports = ->
      'configure': [
        'ryba/hadoop/core'
        'ryba/hadoop/httpfs/configure'
      ]
      'check': [
        'ryba/hadoop/httpfs/wait'
        'ryba/hadoop/httpfs/check'
      ]
      'install': [
        'masson/core/iptables'
        'ryba/hadoop/core'
        'ryba/hadoop/hdfs_client'
        'ryba/hadoop/httpfs/install'
        'ryba/hadoop/httpfs/start'
        'ryba/hadoop/httpfs/wait'
        'ryba/hadoop/httpfs/check'
      ]
      'start': [
        'masson/core/krb5_client/wait'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hadoop/httpfs/start'
      ]
      'stop': 'ryba/hadoop/httpfs/stop'
      'status': 'ryba/hadoop/httpfs/status'
