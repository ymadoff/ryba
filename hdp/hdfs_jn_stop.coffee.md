
# HDFS JournalNode Stop

Stop the JournalNode service. It is recommended to stop a JournalNode after its 
associated NameNodes.

    lifecycle = require './lib/lifecycle'
    module.exports = []

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx

    module.exports.push name: 'HDP JournalNode # Stop', callback: (ctx, next) ->
      lifecycle.jn_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS
