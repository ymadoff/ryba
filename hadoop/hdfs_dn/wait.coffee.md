
# Hadoop HDFS DataNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('../hdfs').configure

    module.exports.push header: 'HDFS DN # Wait IPC', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for context in @contexts 'ryba/hadoop/hdfs_dn', require('./index').configure
          [_, port] = context.config.ryba.hdfs.site['dfs.datanode.address'].split ':'
          host: context.config.host, port: port

    module.exports.push header: 'HDFS DN # Wait HTTP', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for dn_ctx in @contexts 'ryba/hadoop/hdfs_dn', require('./index').configure
          protocol = if dn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
          [_, port] = dn_ctx.config.ryba.hdfs.site["dfs.datanode.#{protocol}.address"].split ':'
          host: dn_ctx.config.host, port: port
