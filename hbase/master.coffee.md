---
title: 
layout: module
---

# HBase Master

    module.exports = []

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      # require('../hadoop/hdfs').configure ctx
      require('./_').configure ctx
      {realm, hbase_site} = ctx.config.ryba
      ctx.config.ryba.hbase_admin ?= {}
      ctx.config.ryba.hbase_admin.principal ?= "#{hbase_site['hbase.superuser']}@#{realm}"
      ctx.config.ryba.hbase_admin.password ?= "hbase123"
      hbase_site['hbase.master.port'] ?= '60000'
      hbase_site['hbase.master.info.port'] ?= '60010'

    # module.exports.push commands: 'backup', modules: 'ryba/hbase/master_backup'

    module.exports.push commands: 'check', modules: 'ryba/hbase/master_check'

    module.exports.push commands: 'install', modules: 'ryba/hbase/master_install'

    module.exports.push commands: 'start', modules: 'ryba/hbase/master_start'

    # module.exports.push commands: 'status', modules: 'ryba/hbase/master_status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/master_stop'
