
# HBase Master Wait

    module.exports =  header: 'HBase Master Wait', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        header: 'RPC Port'
        servers: for hm_ctx in @contexts 'ryba/hbase/master'
          host: hm_ctx.config.host
          port: hm_ctx.config.ryba.hbase.master.site['hbase.master.port']
      @wait_connect
        header: 'HTTP Port'
        servers: for hm_ctx in @contexts 'ryba/hbase/master'
          host: hm_ctx.config.host
          port: hm_ctx.config.ryba.hbase.master.site['hbase.master.info.port']
