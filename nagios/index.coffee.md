
# Nagios Install

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('masson/commons/java').configure ctx
      require('../zookeeper/client').configure ctx
      require('../hadoop/hdfs').configure ctx
      require('../hadoop/yarn').configure ctx
      require('../hbase/regionserver').configure ctx
      require('../hbase/master').configure ctx
      require('../hive/server').configure ctx
      require('../hive/webhcat').configure ctx
      require('../ganglia/collector').configure ctx
      require('../oozie/server').configure ctx
      require('../hue/index').configure ctx
      nagios = ctx.config.ryba.nagios ?= {}
      nagios.overwrite ?= false
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
      # Admin
      nagios.admin_username ?= 'nagiosadmin'
      nagios.admin_password ?= 'nagios123'
      nagios.admin_email ?= ''
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
        'hiveserver': ctx.hosts_with_module 'ryba/hive/server'
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

    # module.exports.push commands: 'backup', modules: 'ryba/nagios/backup'

    module.exports.push commands: 'check', modules: 'ryba/nagios/check'

    module.exports.push commands: 'install', modules: [
      'ryba/nagios/install'
      'ryba/nagios/start'
      'ryba/nagios/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/nagios/start'

    # module.exports.push commands: 'status', modules: 'ryba/nagios/status'

    module.exports.push commands: 'stop', modules: 'ryba/nagios/stop'



