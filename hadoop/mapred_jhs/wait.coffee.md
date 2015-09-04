
# MapReduce JobHistoryServer Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

    module.exports.push name: 'MapReduce JHS # Wait', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for jhs_ctx in @contexts 'ryba/hadoop/mapred_jhs', require('./index').configure
          [_, port] = jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.address'].split ':'
          host: jhs_ctx.config.host, port: port
