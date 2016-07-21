
# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrator can  provision, 
manage and monitor a Hadoop cluster.

    module.exports = ->
      'configure': 'ryba/ambari/server/configure'
      'install': [
        'masson/commons/java'
        'ryba/commons/db_admin'
        'ryba/ambari/server/install'
        'ryba/ambari/server/start'
      ]
      'start': 'ryba/ambari/server/start'
      'stop': 'ryba/ambari/server/stop'

[Ambari-server]: http://ambari.apache.org
