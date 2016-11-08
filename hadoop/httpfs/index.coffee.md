
# HDFS HttpFS

HttpFS is a server that provides a REST HTTP gateway supporting all HDFS File
System operations (read and write). And it is inteoperable with the webhdfs REST
HTTP API.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        hdfs_client: implicit: true, module: 'ryba/hadoop/hdfs_client'
      configure:
        'ryba/hadoop/httpfs/configure'
      commands:
        'check':
          'ryba/hadoop/httpfs/check'
        'install': [
          'ryba/hadoop/httpfs/install'
          'ryba/hadoop/httpfs/start'
          'ryba/hadoop/httpfs/check'
        ]
        'start': 'ryba/hadoop/httpfs/start'
        'stop': 'ryba/hadoop/httpfs/stop'
        'status': 'ryba/hadoop/httpfs/status'
