---
title: 
layout: module
---

# HBase RegionServer

    module.exports = []
    
    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../hadoop/hdfs').configure ctx
      require('./_').configure ctx
      {hbase_site} = ctx.config.ryba
      hbase_site['hbase.regionserver.port'] ?= '60020'
      hbase_site['hbase.regionserver.info.port'] ?= '60030'

    # module.exports.push commands: 'backup', modules: 'ryba/hbase/regionserver_backup'

    module.exports.push commands: 'check', modules: 'ryba/hbase/regionserver_check'

    module.exports.push commands: 'install', modules: 'ryba/hbase/regionserver_install'

    module.exports.push commands: 'start', modules: 'ryba/hbase/regionserver_start'

    # module.exports.push commands: 'status', modules: 'ryba/hbase/regionserver_status'

    module.exports.push commands: 'stop', modules: 'ryba/hbase/regionserver_stop'
