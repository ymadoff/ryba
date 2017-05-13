
# MapReduce JobHistoryServer Wait

    module.exports = header: 'MapReduce JHS Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.wait_tcp = for jhs_ctx in @contexts 'ryba/hadoop/mapred_jhs'
        [fqdn, port] = jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.address'].split ':'
        host: fqdn, port: port
      options.wait_webapp = for jhs_ctx in @contexts 'ryba/hadoop/mapred_jhs'
        protocol = if jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
        [fqdn, port] = jhs_ctx.config.ryba.mapred.site["mapreduce.jobhistory.webapp.#{protocol}address"].split ':'
        host: fqdn, port: port

## TCP

      @connection.wait
        header: 'TCP'
        servers: options.wait_tcp

## HTTP

      @connection.wait
        header: 'HTTP'
        servers: options.wait_webapp
