

# MapReduce JHS Check

    module.exports = header: 'MapReduce JHS Check ', label_true: 'CHECKED', handler: ->
      {mapred} = @config.ryba

## Wait

Wait for the server to be started before executing the tests.

      @call once: true, 'ryba/hadoop/mapred_jhs/wait'

## Check HTTP

Check if the JobHistoryServer is started with an HTTP REST command. Once
started, the server take some time before it can correctly answer HTTP request.
For this reason, the "retry" property is set to the high value of "10".

      protocol = if mapred.site['mapreduce.jobhistory.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      [host, port] = if protocol is 'http'
      then mapred.site['mapreduce.jobhistory.webapp.address'].split ':'
      else mapred.site['mapreduce.jobhistory.webapp.https.address'].split ':'
      @system.execute
        header: 'HTTP'
        retry: 200
        cmd: mkcmd.test @, """
        curl -s --insecure --negotiate -u : #{protocol}://#{host}:#{port}/ws/v1/history/info
        """
        # code_skipped: 2 # doesnt seems to be used
      , (err, checked, stdout) ->
        throw err if err
        JSON.parse(stdout).historyInfo.hadoopVersion

## Dependencies

    mkcmd = require '../../lib/mkcmd'
