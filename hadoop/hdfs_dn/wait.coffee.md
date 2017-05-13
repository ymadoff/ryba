
# Hadoop HDFS DataNode Wait

    module.exports = header: 'HDFS DN Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.wait_ipc = for context in @contexts 'ryba/hadoop/hdfs_dn'
        [_, port] = context.config.ryba.hdfs.site['dfs.datanode.address'].split ':'
        host: context.config.host, port: port
      options.wait_http = for dn_ctx in @contexts 'ryba/hadoop/hdfs_dn'
        protocol = if dn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        [_, port] = dn_ctx.config.ryba.hdfs.site["dfs.datanode.#{protocol}.address"].split ':'
        host: dn_ctx.config.host, port: port

## Wait for all datanode IPC Ports

Port is defined in the "dfs.datanode.address" property of hdfs-site. The default
value is 50020.

      @connection.wait
        header: 'IPC'
        servers: options.wait_ipc

## Wait for all datanode HTTP Ports

Port is defined in the "dfs.datanode.https.address" property of hdfs-site. The default
value is 50475.

      @connection.wait
        header: 'HTTP'
        timeout: -1
        label_true: 'READY'
        servers: options.wait_http
