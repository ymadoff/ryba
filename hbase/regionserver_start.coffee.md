
# HBase Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./_').configure

## Start HBase Region Server

Execute these commands on all RegionServers.

    module.exports.push name: 'HBase RegionServer # Start', label_true: 'STARTED', callback: (ctx, next) ->
      lifecycle.hbase_regionserver_start ctx, next
