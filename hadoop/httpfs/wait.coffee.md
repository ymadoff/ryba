
# Hadoop HDFS NameNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('../hdfs').configure

    module.exports.push header: 'HDFS NN # Wait', timeout: -1, label_true: 'READY', handler:  ->
      @wait_connect
        servers: for httpfs_ctx in @contexts 'ryba/hadoop/httpfs'
          host: httpfs_ctx.config.host, port: httpfs_ctx.config.ryba.httpfs.http_port
