
# Apache NiFi Node Server Wait

    module.exports = header: 'NiFi Node Server Wait', label_true: 'READY', timeout: -1, handler: ->
      nifi_nodes = @contexts 'ryba/nifi/node'
      {nifi} = @config.ryba
      @connection.wait
        servers: for ctx in nifi_nodes
          host: ctx.config.host
          port: ctx.config.ryba.nifi.node.config.properties['nifi.cluster.node.protocol.port']
