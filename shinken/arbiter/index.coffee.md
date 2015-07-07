x
# Shinken Arbiter

Loads the configuration files and dispatches the host and service objects to the
scheduler(s). Watchdog for all other processes and responsible for initiating
failovers if an error is detected. Can route check result events from a Receiver
to its associated Scheduler. Host the WebUI.

    module.exports = []

## Configure

    module.exports.push module.exports.configure = (ctx) ->
      require('../').configure ctx
      {shinken} = ctx.config.ryba
      require('masson/commons/java').configure ctx
      require('../../zookeeper/client').configure ctx
      require('../../hadoop/hdfs').configure ctx
      # require('../hadoop/yarn').configure ctx
      require('../../hbase/regionserver').configure ctx
      require('../../hbase/master').configure ctx
      require('../../hive/hcatalog').configure ctx
      require('../../hive/server2').configure ctx
      require('../../hive/webhcat').configure ctx
      require('../../ganglia/collector').configure ctx
      require('../../oozie/server').configure ctx
      require('../../hue').configure ctx
      shinken.overwrite ?= false
      # Arbiter specific configuration
      shinken.arbiter ?= {}
      # Config
      config = shinken.arbiter.config ?= {}
      config.port ?= 7770
      config.modules = [config.modules] if typeof config.modules is 'string'
      config.modules ?= ['named-pipe']
      config.distributed ?= ctx.hosts_with_module('ryba/shinken/arbiter').length > 1
      config.hostname ?= ctx.config.host
      config.user ?= shinken.user.name
      config.group ?= shinken.group.name
      config.host ?= '0.0.0.0'
      config.spare ?= shinken.config.spare
      config.use_ssl ?= shinken.config.use_ssl
      config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
      # Kerberos
      #shinken.keytab ?= '/etc/security/keytabs/shinken.service.keytab'
      #shinken.principal ?= "shinken/#{ctx.config.host}@#{ctx.config.ryba.realm}"
      #shinken.plugin_dir ?= '/usr/lib64/shinken/plugins'
      # WebUI Users
      shinken.config.users ?= {}
      if Object.getOwnPropertyNames(shinken.config.users).length is 0
        shinken.config.users.shinken =
          password: 'shinken123'
          alias: 'Shinken Admin'
          email: ''
          admin: true
      # WebUI Groups
      shinken.config.groups ?= {}
      if Object.getOwnPropertyNames(shinken.config.groups).length is 0
        shinken.config.groups.admins =
          alias: 'Shinken Administrators'
          members: ['shinken']
      shinken.config.hostgroups ?=
        'namenode': ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
        'snamenode': ctx.hosts_with_module 'ryba/hadoop/hdfs_snn'
        'slaves': ctx.hosts_with_module 'ryba/hadoop/hdfs_dn'
        'agent-servers': [] # ctx.hosts_with_module 'ryba/ambari/agent'
        'shinken-server': ctx.hosts_with_module 'ryba/shinken'
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
      for host, v of shinken.config.hostgroups
        shinken.config.hostgroups[host] = if v? and v.length > 0 then v else null

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/shinken/arbiter/backup'

    module.exports.push commands: 'check', modules: 'ryba/shinken/arbiter/check'

    module.exports.push commands: 'install', modules: [
      'ryba/shinken/arbiter/install'
      'ryba/shinken/arbiter/start'
      # 'ryba/shinken/arbiter/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/shinken/arbiter/start'

    # module.exports.push commands: 'status', modules: 'ryba/shinken/arbiter/status'

    module.exports.push commands: 'stop', modules: 'ryba/shinken/arbiter/stop'
