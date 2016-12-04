
# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrator can  provision, 
manage and monitor a Hadoop cluster.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
      configure: 'ryba/ambari/server/configure'
      commands:
        'install': [
          'ryba/ambari/server/install'
          'ryba/ambari/server/start'
        ]
        'start': 'ryba/ambari/server/start'
        'stop': 'ryba/ambari/server/stop'

[Ambari-server]: http://ambari.apache.org
