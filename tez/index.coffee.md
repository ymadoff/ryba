
# Tez

[Apache Tez][tez] is aimed at building an application framework which allows for
a complex directed-acyclic-graph of tasks for processing data. It is currently
built atop Apache Hadoop YARN.

    module.exports = []

## Configuration

A list for configuration properties supported by HDP 2.2 is available on the
[Tez manual instructions][instructions].

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/core/krb5_client').configure ctx
      require('../hadoop/core').configure ctx
      {ryba} = ctx.config
      hdfs_url = ryba.core_site['fs.defaultFS']
      rm_contexts = ctx.contexts 'ryba/hadoop/yarn_rm', require('../hadoop/yarn_rm').configure
      ryba.tez ?= {}
      ryba.tez.env ?= {}
      ryba.tez.env['TEZ_CONF_DIR'] ?= '/etc/tez/conf'
      ryba.tez.env['TEZ_JARS'] ?= '/usr/hdp/current/tez-client/*:/usr/hdp/current/tez-client/lib/*'
      ryba.tez.env['HADOOP_CLASSPATH'] ?= '$TEZ_CONF_DIR:$TEZ_JARS:$HADOOP_CLASSPATH'
      ryba.tez.tez_site ?= {}
      # ryba.tez.tez_site['tez.lib.uris'] ?= "#{hdfs_url}/apps/tez/,#{hdfs_url}/apps/tez/lib/"
      ryba.tez.tez_site['tez.lib.uris'] ?= "/hdp/apps/${hdp.version}/tez/tez.tar.gz"
      # For documentation purpose in case we HDFS_DELEGATION_TOKEN in hive queries
      # Following line: ryba.tez.tez_site['tez.am.am.complete.cancel.delegation.tokens'] ?= 'false'
      # Renamed to: ryba.tez.tez_site['tez.cancel.delegation.tokens.on.completion'] ?= 'false'
      # Tez UI
      ryba.tez.tez_site['tez.runtime.convert.user-payload.to.history-text'] ?= 'true' if ctx.hosts_with_module('ryba/tez/ui').length

## Configuration for Resource Allocation

      memory_per_container = 512
      rm_memory_max_mb = rm_contexts[0].config.ryba.yarn.site['yarn.scheduler.maximum-allocation-mb']
      rm_memory_min_mb = rm_contexts[0].config.ryba.yarn.site['yarn.scheduler.minimum-allocation-mb']

      am_memory_mb = ryba.tez.tez_site['tez.am.resource.memory.mb'] or memory_per_container
      am_memory_mb = Math.min rm_memory_max_mb, am_memory_mb
      am_memory_mb = Math.max rm_memory_min_mb, am_memory_mb
      ryba.tez.tez_site['tez.am.resource.memory.mb'] = am_memory_mb

      tez_memory_xmx = /-Xmx(.*?)m/.exec(ryba.tez.tez_site['hive.tez.java.opts'])?[1] or Math.floor .8 * am_memory_mb
      tez_memory_xmx = Math.min rm_memory_max_mb, tez_memory_xmx
      ryba.tez.tez_site['hive.tez.java.opts'] ?= "-Xmx#{tez_memory_xmx}m"
      require('./deprecated') ctx

## Commands

    module.exports.push commands: 'check', modules: 'ryba/tez/check'

    module.exports.push commands: 'install', modules: [
      'ryba/tez/install'
      'ryba/tez/check'
    ]

[tez]: http://tez.apache.org/
[instructions]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.8.4)
