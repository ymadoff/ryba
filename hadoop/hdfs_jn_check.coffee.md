
# Hadoop HDFS JournalNode Check

Check if the JournalNode is running as expected.

    mkcmd = require '../lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push (ctx) ->
      require('./core_ssl').configure ctx
      require('./hdfs_jn').configure ctx

    module.exports.push name: 'HDFS JN Check # SPNEGO', label_true: 'CHECKED', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      protocol = if hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      port = hdfs.site["dfs.journalnode.#{protocol}-address"].split(':')[1]
      ctx.execute
        cmd: mkcmd.hdfs ctx, "curl --negotiate -k -u : #{protocol}://#{ctx.config.host}:#{port}/jmx?qry=Hadoop:service=JournalNode,name=JournalNodeInfo"
      , (err, executed, stdout) ->
        return next err if err
        try
          data = JSON.parse stdout
          throw Error "Invalid Response" unless data.beans[0].name is 'Hadoop:service=JournalNode,name=JournalNodeInfo'
        catch err then return next err
        return next null, true


