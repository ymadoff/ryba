
# HBase Rest server Wait

    module.exports = header: 'HBase Rest Wait', label_true: 'READY', timeout: -1, handler: ->
      @wait_connect
        servers: for rest_ctx in @contexts 'ryba/hbase/rest'
          host: rest_ctx.config.host, port: [
            rest_ctx.config.ryba.hbase.rest.site['hbase.rest.port']
            rest_ctx.config.ryba.hbase.rest.site['hbase.rest.info.port']
          ]
