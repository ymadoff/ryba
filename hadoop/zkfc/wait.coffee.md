
# Hadoop HDFS NameNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('../hdfs').configure

    module.exports.push name: 'ZKFC # Wait', timeout: -1, label_true: 'READY', handler:  ->
      zkfc_ctxs = @contexts 'ryba/hadoop/zkfc'#, require('./index').configure
      @wait_connect
        servers: for zkfc_ctx in zkfc_ctxs
          host: zkfc_ctx.config.host, port: zkfc_ctx.config.ryba.hdfs.site['dfs.ha.zkfc.port']

## Dependencies

    mkcmd = require '../../lib/mkcmd'
