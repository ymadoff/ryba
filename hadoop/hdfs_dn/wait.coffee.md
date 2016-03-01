
# Hadoop HDFS DataNode Wait

    module.exports = header: 'HDFS DN Wait', timeout: -1, label_true: 'READY', handler: ->

      @wait_connect
        header: 'IPC'
        servers: for context in @contexts 'ryba/hadoop/hdfs_dn'
          [_, port] = context.config.ryba.hdfs.site['dfs.datanode.address'].split ':'
          host: context.config.host, port: port

      @wait_connect
        header: 'HTTP'
        timeout: -1
        label_true: 'READY'
        servers: for dn_ctx in @contexts 'ryba/hadoop/hdfs_dn'
          protocol = if dn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
          [_, port] = dn_ctx.config.ryba.hdfs.site["dfs.datanode.#{protocol}.address"].split ':'
          host: dn_ctx.config.host, port: port
