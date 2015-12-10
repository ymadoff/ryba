
# YARN Timeline Server Check

Check the Timeline Server.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_ts/wait'
    # module.exports.push require('./index').configure

    module.exports.push header: 'YARN ATS # Check HTTP', timeout: -1, label_true: 'CHECKED', handler: ->
      {yarn} = @config.ryba
      protocol = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      address_key = if protocol is 'http' then "address" else "https.address"
      address = yarn.site["yarn.timeline-service.webapp.#{address_key}"]
      @execute
        cmd: mkcmd.hdfs @, "curl --negotiate -k -u : #{protocol}://#{address}/jmx?qry=Hadoop:service=ApplicationHistoryServer,name=JvmMetrics"
      , (err, executed, stdout) ->
        throw err if err
        data = JSON.parse stdout
        throw Error "Invalid Response" unless Array.isArray data?.beans

# Dependencies

    mkcmd = require '../../lib/mkcmd'
