
# Hive Server2

HiveServer2 (HS2) is a server interface that enables remote clients to execute
queries against Hive and retrieve the results. The current implementation, based
on Thrift RPC, is an improved version of HiveServer and supports multi-client
concurrency and authentication. It is designed to provide better support for
open API clients like JDBC and ODBC.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        # mapred_client: implicit: true, module: 'ryba/hadoop/mapred_client'
        # tez: implicit: true, module: 'ryba/tez'
        # db_admin: 'ryba/commons/db_admin'
        hadoop_core: 'ryba/hadoop/core'
        # hive_client: 'ryba/hive/client'
        hive_hcatalog: 'ryba/hive/hcatalog'
        # hbase_client: 'ryba/hbase/client'
      configure:[
        'ryba/hive/client/configure'
        'ryba/hive/server2/configure'
      ]
      commands:
        'install': [
          'ryba/hive/client/install'
          'ryba/hive/server2/install'
          'ryba/hive/server2/start'
          'ryba/hive/server2/check'
        ]
        'start':
          'ryba/hive/server2/start'
        'check':
          'ryba/hive/server2/check'
        'status':
          'ryba/hive/server2/status'
        'stop':
          'ryba/hive/server2/stop'
        'wait':
          'ryba/hive/server2/wait'
        'backup':
          'ryba/hive/server2/backup'
