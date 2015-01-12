
# HBase Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./_').configure

## Start HBase Master

Execute these commands on the HBase Master host machine.

    module.exports.push name: 'HBase Master # Start', label_true: 'STARTED', callback: (ctx, next) ->
      lifecycle.hbase_master_start ctx, next
