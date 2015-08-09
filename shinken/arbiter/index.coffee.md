
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
      # Additionnal modules to install
      shinken.arbiter.modules ?= {}
      # Config
      config = shinken.arbiter.config ?= {}
      config.port ?= 7770
      config.modules = [config.modules] if typeof config.modules is 'string'
      config.modules ?= []
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
        'ambari-agents': ctx.hosts_with_module 'ryba/shinken/ambari/agent'
        'ambari-servers': ctx.hosts_with_module 'ryba/shinken/ambari/server'
        'elasticsearch-servers': ctx.hosts_with_module 'ryba/elasticsearch'
        'falcon-servers': ctx.hosts_with_module 'ryba/falcon'
        'hdfs-clients': ctx.hosts_with_module 'ryba/hadoop/hdfs_client'
        'hdfs-datanodes': ctx.hosts_with_module 'ryba/hadoop/hdfs_dn'
        'hdfs-journalnodes': ctx.hosts_with_module 'ryba/hadoop/hdfs_jn'
        'hdfs-namenodes': ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
        'hdfs-zkfcs': ctx.hosts_with_module 'ryba/hadoop/zkfc'
        'mapreduce-clients': ctx.hosts_with_module 'ryba/hadoop/mapred_client'
        'mapreduce-jhs': ctx.hosts_with_module 'ryba/hadoop/mapred_jhs'
        'yarn-clients': ctx.hosts_with_module 'ryba/hadoop/yarn_client'
        'yarn-nodemanagers': ctx.hosts_with_module 'ryba/hadoop/yarn_nm'
        'yarn-resourcemanagers': ctx.hosts_with_module 'ryba/hadoop/yarn_rm'
        'yarn-timeline-servers': ctx.hosts_with_module 'ryba/hadoop/yarn_ts'
        'hbase-clients': ctx.hosts_with_module 'ryba/hbase/client'
        'hbase-masters': ctx.hosts_with_module 'ryba/hbase/master'
        'hbase-regionservers': ctx.hosts_with_module 'ryba/hbase/regionserver'
        'hbase-rest-servers': ctx.hosts_with_module 'ryba/hbase/rest'
        'hbase-thrift-servers': ctx.hosts_with_module 'ryba/hbase/thrift'
        'hive-clients': ctx.hosts_with_module 'ryba/hive/client'
        'hive-hcatalog-servers': ctx.hosts_with_module 'ryba/hive/hcatalog'
        'hive-servers': ctx.hosts_with_module 'ryba/hive/server2'
        'hive-webhcat-servers': ctx.hosts_with_module 'ryba/hive/webhcat'
        'hue-servers': ctx.hosts_with_module 'ryba/hue'
        'kafka-brokers': ctx.hosts_with_module 'ryba/kafka/broker'
        'kafka-consumers': ctx.hosts_with_module 'ryba/kafka/consumer'
        'kafka-producers': ctx.hosts_with_module 'ryba/kafka/producer'
        'mongodb-servers': ctx.hosts_with_module 'ryba/mongodb'
        'mongodb-shards': ctx.hosts_with_module 'ryba/mongodb/shard'
        'oozie-clients': ctx.hosts_with_module 'ryba/oozie/client'
        'oozie-servers': ctx.hosts_with_module 'ryba/oozie/servers'
        'phoenix-clients': ctx.host_with_module 'ryba/phoenix/client'
        'rexster-servers': ctx.host_with_module 'ryba/rexster'
        'shinken-arbiters': ctx.hosts_with_module 'ryba/shinken/arbiter'
        'shinken-brokers': ctx.hosts_with_module 'ryba/shinken/broker'
        'shinken-pollers': ctx.hosts_with_module 'ryba/shinken/poller'
        'shinken-reactionners': ctx.hosts_with_module 'ryba/shinken/reactionner'
        'shinken-receivers': ctx.hosts_with_module 'ryba/shinken/receiver'
        'shinken-schedulers': ctx.hosts_with_module 'ryba/shinken/scheduler'
        'solr-servers': ctx.hosts_with_module 'ryba/solr'
        'spark-clients': ctx.hosts_with_module 'ryba/spark/client'
        'spark-history-servers': ctx.hosts_with_module 'ryba/history_server'
        'titan-servers': ctx.hosts_with_module 'ryba/titan'
        'zeppelin-servers': ctx.hosts_with_module 'ryba/zeppelin'
        'zookeeper-clients': ctx.hosts_with_module 'ryba/zookeeper/client'
        'zookeeper-servers': ctx.hosts_with_module 'ryba/zookeeper/server'
      shinken.config.servicegroups ?= ['ambari','elasticsearch','falcon', 'flume',
        'hadoop', 'hdfs', 'hbase', 'hive', 'hue', 'kafka', 'mapreduce', 'mongodb',
        'oozie', 'phoenix', 'rexster', 'shinken', 'solr', 'storm', 'spark', 'titan',
        'yarn', 'zeppelin', 'zookeeper'
      ]

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
