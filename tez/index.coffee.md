
# Tez

[Apache Tez][tez] is aimed at building an application framework which allows for
a complex directed-acyclic-graph of tasks for processing data. It is currently
built atop Apache Hadoop YARN.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/core/krb5_client').configure ctx
      require('../hadoop/core').configure ctx
      {ryba} = ctx.config
      hdfs_url = ryba.core_site['fs.defaultFS']
      rm_contexts = ctx.contexts 'ryba/hadoop/yarn_rm'
      rm_m = memory rm_contexts[0]
      ryba.tez ?= {}
      ryba.tez.tez_site ?= {}
      ryba.tez.tez_site['tez.lib.uris'] ?= "#{hdfs_url}/apps/tez/,#{hdfs_url}/apps/tez/lib/"
      ryba.tez.tez_site['tez.am.resource.memory.mb'] ?= '2048'
      ryba.tez.tez_site['tez.am.resource.memory.mb'] = Math.min ryba.tez.tez_site['tez.am.resource.memory.mb'], rm_m.yarn_site['yarn.scheduler.maximum-allocation-mb']
      ryba.tez.env ?= {}
      ryba.tez.env['TEZ_CONF_DIR'] ?= '/etc/tez/conf'
      ryba.tez.env['TEZ_JARS'] ?= '/usr/lib/tez/*:/usr/lib/tez/lib/*'

    # module.exports.push commands: 'check', modules: 'ryba/falcon/check'

    module.exports.push commands: 'install', modules: [
      'ryba/tez/install'
      'ryba/tez/check'
    ]

## Dependencies

    memory = require '../lib/memory'

[tez]: http://tez.apache.org/
