---
title: 
layout: module
---

# HBase RestServer

    module.exports = []

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../hadoop/hdfs').configure ctx
      require('./_').configure ctx

    # module.exports.push commands: 'backup', modules: 'ryba/hbase/regionserver_backup'

    # module.exports.push commands: 'check', modules: 'ryba/hbase/regionserver_check'

    module.exports.push commands: 'install', modules: 'ryba/hbase/restserver_install'

    # module.exports.push commands: 'start', modules: 'ryba/hbase/regionserver_start'

    # module.exports.push commands: 'status', modules: 'ryba/hbase/regionserver_status'

    # module.exports.push commands: 'stop', modules: 'ryba/hbase/regionserver_stop'