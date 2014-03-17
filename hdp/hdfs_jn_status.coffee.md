
# HDFS JournalNode Status

Display the status of the JournalNode as "STARTED" or "STOPPED".

    lifecycle = require './lib/lifecycle'
    module.exports = []

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx

    module.exports.push name: 'HDP JournalNode # Status', callback: (ctx, next) ->
      lifecycle.jn_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'
