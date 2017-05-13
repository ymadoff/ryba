
# HBase Master Wait

    module.exports =  header: 'HBase Master Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.wait_rcp = for hm_ctx in @contexts 'ryba/hbase/master'
        host: hm_ctx.config.host
        port: hm_ctx.config.ryba.hbase.master.site['hbase.master.port']
      options.wait_http = for hm_ctx in @contexts 'ryba/hbase/master'
        host: hm_ctx.config.host
        port: hm_ctx.config.ryba.hbase.master.site['hbase.master.info.port']

## RPC Port

      @connection.wait
        header: 'RPC'
        servers: options.wait_rcp

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.wait_http
