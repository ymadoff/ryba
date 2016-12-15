
# Hadoop HDFS NameNode Wait

    module.exports = header: 'HDFS HttpFS Wait', timeout: -1, label_true: 'READY', handler:  ->
      @connection.wait
        header: 'HTTP Port'
        servers: for httpfs_ctx in @contexts 'ryba/hadoop/httpfs'
          host: httpfs_ctx.config.host, port: httpfs_ctx.config.ryba.httpfs.http_port
