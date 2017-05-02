
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

## Environment

      nagios.overwrite ?= false
      nagios.log_dir = '/var/log/nagios'

## Identities

      # Groups
      nagios.group = name: nagios.group if typeof nagios.group is 'string'
      nagios.group ?= {}
      nagios.group.name ?= 'nagios'
      nagios.group.system ?= true
      nagios.groupcmd = name: nagios.group if typeof nagios.group is 'string'
      nagios.groupcmd ?= {}
      nagios.groupcmd.name ?= 'nagiocmd'
      nagios.groupcmd.system ?= true     
      # User
      nagios.user = name: nagios.user if typeof nagios.user is 'string'
      nagios.user ?= {}
      nagios.user.name ?= 'nagios'
      nagios.user.system ?= true
      nagios.user.gid = nagios.group.name
      nagios.user.comment ?= 'Nagios User'
      nagios.user.home = '/var/log/nagios'
      nagios.user.shell = '/bin/sh' 
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

## Kerberos

      nagios.keytab ?= '/etc/security/keytabs/nagios.service.keytab'
      nagios.principal ?= "nagios/#{@config.host}@#{@config.ryba.realm}"
      nagios.kinit ?= '/usr/bin/kinit'
      nagios.plugin_dir ?= '/usr/lib64/nagios/plugins'
      nagios.hostgroups ?=
        'namenode': @contexts('ryba/hadoop/hdfs_nn').map((ctx) -> ctx.config.host)
        'snamenode': @contexts('ryba/hadoop/hdfs_snn').map((ctx) -> ctx.config.host)
        'slaves': @contexts('ryba/hadoop/hdfs_dn').map((ctx) -> ctx.config.host)
        'agent-servers': [] # @contexts('ryba/ambari/agent'
        'nagios-server': @contexts('ryba/nagios/install').map((ctx) -> ctx.config.host)
        # jobtracker
        'ganglia-server': @contexts('ryba/ganglia/collector').map((ctx) -> ctx.config.host)
        'flume-servers': [] # @contexts('ryba/flume/server'
        'zookeeper-servers': @contexts('ryba/zookeeeper/server').map((ctx) -> ctx.config.host)
        'hbasemasters': @contexts('ryba/hbase/master').map((ctx) -> ctx.config.host)
        'hiveserver': @contexts('ryba/hive/hcatalog').map((ctx) -> ctx.config.host)
        'region-servers': @contexts('ryba/hbase/regionserver').map((ctx) -> ctx.config.host)
        'oozie-server': @contexts('ryba/oozie/server').map((ctx) -> ctx.config.host)
        'webhcat-server': @contexts('ryba/hive/webhcat').map((ctx) -> ctx.config.host)
        'hue-server': @contexts('ryba/hue/install').map((ctx) -> ctx.config.host)
        'resourcemanager': @contexts('ryba/hadoop/yarn_rm').map((ctx) -> ctx.config.host)
        'nodemanagers': @contexts('ryba/hadoop/yarn_nm').map((ctx) -> ctx.config.host)
        'historyserver2': @contexts('ryba/hadoop/servers').map((ctx) -> ctx.config.host)
        'journalnodes': @contexts('ryba/hadoop/hdfs_jn').map((ctx) -> ctx.config.host)
        'nimbus': [] # @contexts('ryba/storm/nimbus').map((ctx) -> ctx.config.host)
        'drpc-server': [] # @contexts('ryba/storm/drpc').map((ctx) -> ctx.config.host)
        'storm_ui': [] # @contexts('ryba/storm/ui').map((ctx) -> ctx.config.host)
        'supervisors': [] # @contexts('ryba/storm/supervisors').map((ctx) -> ctx.config.host)
        'storm_rest_api': [] # @contexts('ryba/storm/rest').map((ctx) -> ctx.config.host)
        'falcon-server': [] # @contexts('ryba/falcon').map((ctx) -> ctx.config.host)
        'ats-servers': @contexts('ryba/ats').map((ctx) -> ctx.config.host)
