

# MapReduce JHS Check

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Check HTTP

Check if the JobHistoryServer is started with an HTTP REST command. Once
started, the server take some time before it can correctly answer HTTP request.
For this reason, the "retry" property is set to the high value of "10".

    module.exports.push name: 'MapReduce JHS # Check HTTP', retry: 200, label_true: 'CHECKED', handler: (ctx, next) ->
      {mapred} = ctx.config.ryba
      protocol = if mapred.site['mapreduce.jobhistory.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      [host, port] = if protocol is 'http'
      then mapred.site['mapreduce.jobhistory.webapp.address'].split ':'
      else mapred.site['mapreduce.jobhistory.webapp.https.address'].split ':'
      ctx.execute
        cmd: mkcmd.test ctx, """
        curl -s --insecure --negotiate -u : #{protocol}://#{host}:#{port}/ws/v1/history/info
        """
        # code_skipped: 2 # doesnt seems to be used
      , (err, checked, stdout) ->
        throw err if err
        JSON.parse(stdout).historyInfo.hadoopVersion
      .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'
