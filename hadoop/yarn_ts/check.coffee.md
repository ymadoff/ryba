
# YARN Timeline Server Check

Check the Timeline Server.

    module.exports = header: 'YARN ATS # Check HTTP', timeout: -1, label_true: 'CHECKED', handler: ->
      {yarn} = @config.ryba

Wait for the server to be started.

      @call once: true, 'ryba/hadoop/yarn_ts/wait'

Check the HTTP server with a JMX request.

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
