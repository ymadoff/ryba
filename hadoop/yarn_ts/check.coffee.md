
# YARN Timeline Server Check

Check the Timeline Server.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_ts/wait'
    module.exports.push require('./index').configure

    module.exports.push name: 'YARN TS # Check HTTP', timeout: -1, label_true: 'CHECKED', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      protocol = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      address_key = if protocol is 'http' then "address" else "https.address"
      address = yarn.site["yarn.timeline-service.webapp.#{address_key}"]
      ctx.execute
        cmd: mkcmd.hdfs ctx, "curl --negotiate -k -u : #{protocol}://#{address}/jmx?qry=Hadoop:service=ApplicationHistoryServer,name=JvmMetrics"
      , (err, executed, stdout) ->
        return next err if err
        data = JSON.parse stdout
        return next Error "Invalid Response" unless Array.isArray data?.beans
      .then next

# Dependencies

    mkcmd = require '../../lib/mkcmd'