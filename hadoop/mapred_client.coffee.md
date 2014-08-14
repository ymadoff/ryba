---
title: 
layout: module
---

# MapRed Client

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/yarn_client'

    module.exports.push module.exports.configure = (ctx) ->
      require('./hdfs').configure ctx
      require('./mapred').configure ctx

    module.exports.push 'ryba/hadoop/mapred'

    module.exports.push name: 'HDP MapRed # Wait JHS', timeout: -1, callback: (ctx, next) ->
      {mapred} = ctx.config.hdp
      # Layout is created by the MapReduce JHS server
      [hostname, port] = mapred['mapreduce.jobhistory.address'].split ':'
      ctx.waitIsOpen hostname, port, (err) ->
        next err, ctx.PASS

    module.exports.push 'ryba/hadoop/mapred_client_check'



