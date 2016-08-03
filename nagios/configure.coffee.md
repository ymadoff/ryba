
# Nagios Configure


## Configure

*   `nagios.users` (object)   
    Each property is a user object. The key is the username.   
*   `oozie.group` (object|string)   
    Each property is a group object. The key is the group name.   

Example

```json
{
  "ryba": {
    "nagios": {
      "users": {
        "nagiosadmin": {
          "password": 'adminpasswd',
          "alias": 'Nagios Admin',
          "email": 'admin@example.com'
        },
        "guest": {
          "password": 'guestpasswd',
          alias: 'Guest',
          email: 'guest@example.com'
        }
      },
      "groups": {
        "admins": {
          "alias": 'Nagios Administrators',
          "members": ['nagiosadmin','guest']
        }
      }
    }
  }
}
```

    module.exports = handler: ->
      # require('masson/commons/java').configure ctx
      # require('../zookeeper/client').configure ctx
      # require('../hadoop/hdfs').configure ctx
      # # require('../hadoop/yarn').configure ctx
      # require('../hbase/regionserver').configure ctx
      # require('../hbase/master').configure ctx
      # require('../hive/hcatalog').configure ctx
      # require('../hive/server2').configure ctx
      # require('../hive/webhcat').configure ctx
      # require('../ganglia/collector').configure ctx
      # require('../oozie/server').configure ctx
      # require('../hue/index').configure ctx
      nagios = @config.ryba.nagios ?= {}
      nagios.overwrite ?= false
      nagios.log_dir = '/var/log/nagios'
      # User
      nagios.user = name: nagios.user if typeof nagios.user is 'string'
      nagios.user ?= {}
      nagios.user.name ?= 'nagios'
      nagios.user.system ?= true
      nagios.user.gid = 'nagios'
      nagios.user.comment ?= 'Nagios User'
      nagios.user.home = '/var/log/nagios'
      nagios.user.shell = '/bin/sh'
      # Groups
      nagios.group = name: nagios.group if typeof nagios.group is 'string'
      nagios.group ?= {}
      nagios.group.name ?= 'nagios'
      nagios.group.system ?= true
      nagios.groupcmd = name: nagios.group if typeof nagios.group is 'string'
      nagios.groupcmd ?= {}
      nagios.groupcmd.name ?= 'nagiocmd'
      nagios.groupcmd.system ?= true      
      # WebUI Users & Groups
      nagios.users ?= {}
      unless Object.keys(nagios.users).length
        nagios.users.nagiosadmin =
          password: 'nagios123'
          alias: 'Nagios Admin'
          email: ''
      nagios.groups ?= {}
      unless Object.keys(nagios.groups).length
        members = if nagios.users.nagiosadmin
        then ['nagiosadmin']
        else Object.keys nagios.users
        nagios.groups.admins =
          alias: 'Nagios Administrators'
          members: members
      # Kerberos
      nagios.keytab ?= '/etc/security/keytabs/nagios.service.keytab'
      nagios.principal ?= "nagios/#{@config.host}@#{@config.ryba.realm}"
      nagios.kinit ?= '/usr/bin/kinit'
      nagios.plugin_dir ?= '/usr/lib64/nagios/plugins'
      nagios.hostgroups ?=
        'namenode': @hosts_with_module 'ryba/hadoop/hdfs_nn'
        'snamenode': @hosts_with_module 'ryba/hadoop/hdfs_snn'
        'slaves': @hosts_with_module 'ryba/hadoop/hdfs_dn'
        'agent-servers': [] # @hosts_with_module 'ryba/ambari/agent'
        'nagios-server': @hosts_with_module 'ryba/nagios/install'
        # jobtracker
        'ganglia-server': @hosts_with_module 'ryba/ganglia/collector'
        'flume-servers': [] # @hosts_with_module 'ryba/flume/server'
        'zookeeper-servers': @hosts_with_module 'ryba/zookeeeper/server'
        'hbasemasters': @hosts_with_module 'ryba/hbase/master'
        'hiveserver': @hosts_with_module 'ryba/hive/hcatalog'
        'region-servers': @hosts_with_module 'ryba/hbase/regionserver'
        'oozie-server': @hosts_with_module 'ryba/oozie/server'
        'webhcat-server': @hosts_with_module 'ryba/hive/webhcat'
        'hue-server': @hosts_with_module 'ryba/hue/install'
        'resourcemanager': @hosts_with_module 'ryba/hadoop/yarn_rm'
        'nodemanagers': @hosts_with_module 'ryba/hadoop/yarn_nm'
        'historyserver2': @hosts_with_module 'ryba/hadoop/servers'
        'journalnodes': @hosts_with_module 'ryba/hadoop/hdfs_jn'
        'nimbus': [] # @hosts_with_module 'ryba/storm/nimbus'
        'drpc-server': [] # @hosts_with_module 'ryba/storm/drpc'
        'storm_ui': [] # @hosts_with_module 'ryba/storm/ui'
        'supervisors': [] # @hosts_with_module 'ryba/storm/supervisors'
        'storm_rest_api': [] # @hosts_with_module 'ryba/storm/rest'
        'falcon-server': [] # @hosts_with_module 'ryba/falcon'
        'ats-servers': @hosts_with_module 'ryba/ats'
