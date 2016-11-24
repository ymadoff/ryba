
# Ranger Policy Manager

Apache Ranger offers a centralized security framework to manage fine-grained
access control over Hadoop data access components like Apache Hive and Apache HBase.
Ranger User sync is a process separated from ranger policy manager, which is in charg of
importing user/groups from different sources (LDAP, AD, UNIX).

    module.exports = 
      use:
        java: implicit: true, module: 'masson/commons/java'
        ranger_admin: 'ryba/ranger/admin'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
      configure: 'ryba/ranger/usersync/configure'
      commands:
        'install': [
          'masson/commons/mysql/client'
          'masson/commons/java'
          'ryba/ranger/admin/wait'
          'ryba/ranger/usersync/install'
          'ryba/ranger/usersync/start'
        ]
        'start': [
          'ryba/ranger/admin/wait'
          'ryba/ranger/usersync/start'
        ]
        'stop': [
          'ryba/ranger/usersync/stop'
        ]
