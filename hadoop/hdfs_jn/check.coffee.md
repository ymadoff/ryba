
# Hadoop HDFS JournalNode Check

Check if the JournalNode is running as expected.

    module.exports = header: 'HDFS JN Check', label_true: 'CHECKED', handler: ->
      {hdfs} = @config.ryba

Wait for the JournalNodes.

      @call once: true, 'ryba/hadoop/hdfs_jn/wait'

Test the HTTP server with a JMX request.

      protocol = if hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      port = hdfs.site["dfs.journalnode.#{protocol}-address"].split(':')[1]
      @execute
        header: 'SPNEGO'
        cmd: mkcmd.hdfs @, "curl --negotiate -k -u : #{protocol}://#{@config.host}:#{port}/jmx?qry=Hadoop:service=JournalNode,name=JournalNodeInfo"
      , (err, executed, stdout) ->
        throw err if err
        data = JSON.parse stdout
        throw Error "Invalid Response" unless data.beans[0].name is 'Hadoop:service=JournalNode,name=JournalNodeInfo'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
