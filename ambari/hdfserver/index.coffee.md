
# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrator can  provision, 
manage and monitor a Hadoop cluster.

    module.exports =
      use:
        ssl: implicit: true, module: 'masson/core/ssl'
        java: module: 'masson/commons/java', recommanded: true
        krb5_server: module: 'masson/core/krb5_server'
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
        hadoop: 'ryba/hadoop/core'
      configure: 'ryba/ambari/hdfserver/configure'
      commands:
        'prepare': ->
          options = @config.ryba.ambari_hdfserver
          @call 'ryba/ambari/server/prepare', options
        'check': ->
          options = @config.ryba.ambari_hdfserver
          @call 'ryba/ambari/server/check', options
        'install': ->
          options = @config.ryba.ambari_hdfserver
          @call 'ryba/ambari/server/install', options
          @call 'ryba/ambari/server/start', options
          @call 'ryba/ambari/server/check', options
        'start': 'ryba/ambari/server/start'
        'stop': 'ryba/ambari/server/stop'

[Ambari-server]: http://ambari.apache.org
