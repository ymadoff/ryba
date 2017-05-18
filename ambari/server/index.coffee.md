
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
      configure: 'ryba/ambari/server/configure'
      commands:
        'ambari_blueprint': 'ryba/ambari/server/blueprint'
        'check': 'ryba/ambari/server/check'
        'install': [
          'ryba/ambari/server/install'
          'ryba/ambari/server/start'
          'ryba/ambari/server/check'
        ]
        'start': 'ryba/ambari/server/start'
        'stop': 'ryba/ambari/server/stop'

[Ambari-server]: http://ambari.apache.org
