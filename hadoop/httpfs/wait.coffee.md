
# Hadoop HDFS NameNode Wait

    module.exports = header: 'HDFS HttpFS Wait', timeout: -1, label_true: 'READY', handler:  ->
      options = {}
      options.wait_http = for httpfs_ctx in @contexts 'ryba/hadoop/httpfs'
        host: httpfs_ctx.config.host
        port: httpfs_ctx.config.ryba.httpfs.http_port

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.wait_http
