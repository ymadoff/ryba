
# HDFS JournalNode Start

Start the JournalNode service. It is recommended to start a JournalNode before the
NameNodes. The "phyla/hdp/hdfs_nn" module will wait for all the JournalNodes
to be started on the active NameNode before it check if it must be formated.

    lifecycle = require './lib/lifecycle'
    module.exports = []

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx

    module.exports.push name: 'HDP JournalNode # Start', callback: (ctx, next) ->
      lifecycle.jn_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
