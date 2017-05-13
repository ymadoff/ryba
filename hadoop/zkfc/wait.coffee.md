
# Hadoop ZKFC Wait

    module.exports = header: 'HDFS ZKFC Wait', timeout: -1, label_true: 'READY', handler:  ->
      options = {}
      options.wait = for zkfc_ctx in @contexts 'ryba/hadoop/zkfc'
        host: zkfc_ctx.config.host, port: zkfc_ctx.config.ryba.hdfs.site['dfs.ha.zkfc.port']
      
      @connection.wait
        servers: options.wait
