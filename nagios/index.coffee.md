
# Nagios

[Nagios](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.1/bk_Monitoring_Hadoop_Book/content/monitor-chap3-1.html) is an open source network monitoring system designed to monitor all aspects of your Hadoop cluster (such as hosts, services, and so forth) over the network. It can monitor many facets of your installation, ranging from operating system attributes like CPU and memory usage to the status of applications, files, and more. Nagios provides a flexible, customizable framework for collecting data on the state of your Hadoop cluster.



    module.exports = []

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

    module.exports.configure = (ctx) ->
      require('masson/commons/java').configure ctx
      require('../zookeeper/client').configure ctx
      require('../hadoop/hdfs').configure ctx
      # require('../hadoop/yarn').configure ctx
      require('../hbase/regionserver').configure ctx
      require('../hbase/master').configure ctx
      require('../hive/hcatalog').configure ctx
      require('../hive/server2').configure ctx
      require('../hive/webhcat').configure ctx
      require('../ganglia/collector').configure ctx
      require('../oozie/server').configure ctx
      require('../hue/index').configure ctx
      nagios = ctx.config.ryba.nagios ?= {}
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
      nagios.principal ?= "nagios/#{ctx.config.host}@#{ctx.config.ryba.realm}"
      nagios.kinit ?= '/usr/bin/kinit'
      nagios.plugin_dir ?= '/usr/lib64/nagios/plugins'
      nagios.hostgroups ?=
        'namenode': ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
        'snamenode': ctx.hosts_with_module 'ryba/hadoop/hdfs_snn'
        'slaves': ctx.hosts_with_module 'ryba/hadoop/hdfs_dn'
        'agent-servers': [] # ctx.hosts_with_module 'ryba/ambari/agent'
        'nagios-server': ctx.hosts_with_module 'ryba/nagios/install'
        # jobtracker
        'ganglia-server': ctx.hosts_with_module 'ryba/ganglia/collector'
        'flume-servers': [] # ctx.hosts_with_module 'ryba/flume/server'
        'zookeeper-servers': ctx.hosts_with_module 'ryba/zookeeeper/server'
        'hbasemasters': ctx.hosts_with_module 'ryba/hbase/master'
        'hiveserver': ctx.hosts_with_module 'ryba/hive/hcatalog'
        'region-servers': ctx.hosts_with_module 'ryba/hbase/regionserver'
        'oozie-server': ctx.hosts_with_module 'ryba/oozie/server'
        'webhcat-server': ctx.hosts_with_module 'ryba/hive/webhcat'
        'hue-server': ctx.hosts_with_module 'ryba/hue/install'
        'resourcemanager': ctx.hosts_with_module 'ryba/hadoop/yarn_rm'
        'nodemanagers': ctx.hosts_with_module 'ryba/hadoop/yarn_nm'
        'historyserver2': ctx.hosts_with_module 'ryba/hadoop/servers'
        'journalnodes': ctx.hosts_with_module 'ryba/hadoop/hdfs_jn'
        'nimbus': [] # ctx.hosts_with_module 'ryba/storm/nimbus'
        'drpc-server': [] # ctx.hosts_with_module 'ryba/storm/drpc'
        'storm_ui': [] # ctx.hosts_with_module 'ryba/storm/ui'
        'supervisors': [] # ctx.hosts_with_module 'ryba/storm/supervisors'
        'storm_rest_api': [] # ctx.hosts_with_module 'ryba/storm/rest'
        'falcon-server': [] # ctx.hosts_with_module 'ryba/falcon'
        'ats-servers': ctx.hosts_with_module 'ryba/ats'

## Commands

    module.exports.push commands: 'backup', modules: 'ryba/nagios/backup'

    module.exports.push commands: 'check', modules: 'ryba/nagios/check'

    module.exports.push commands: 'install', modules: [
      'ryba/nagios/install'
      'ryba/nagios/check' # Must be executed before start
      'ryba/nagios/start'
    ]

    module.exports.push commands: 'start', modules: 'ryba/nagios/start'

    # module.exports.push commands: 'status', modules: 'ryba/nagios/status'

    module.exports.push commands: 'stop', modules: 'ryba/nagios/stop'
