
# Hadoop ZKFC Wait

    module.exports = header: 'HDFS ZKFC # Wait', timeout: -1, label_true: 'READY', handler:  ->
      zkfc_ctxs = @contexts 'ryba/hadoop/zkfc'
      @connection.wait
        servers: for zkfc_ctx in zkfc_ctxs
          host: zkfc_ctx.config.host, port: zkfc_ctx.config.ryba.hdfs.site['dfs.ha.zkfc.port']
