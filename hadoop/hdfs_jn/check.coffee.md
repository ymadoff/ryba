
# Hadoop HDFS JournalNode Check

Check if the JournalNode is running as expected.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    # module.exports.push (ctx) ->
    #   require('../core_ssl').configure ctx
    #   require('./index').configure ctx

    module.exports.push header: 'HDFS JN # Check SPNEGO', label_true: 'CHECKED', handler: ->
      {hdfs} = @config.ryba
      protocol = if hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      port = hdfs.site["dfs.journalnode.#{protocol}-address"].split(':')[1]
      @execute
        cmd: mkcmd.hdfs @, "curl --negotiate -k -u : #{protocol}://#{@config.host}:#{port}/jmx?qry=Hadoop:service=JournalNode,name=JournalNodeInfo"
      , (err, executed, stdout) ->
        throw err if err
        data = JSON.parse stdout
        throw Error "Invalid Response" unless data.beans[0].name is 'Hadoop:service=JournalNode,name=JournalNodeInfo'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
