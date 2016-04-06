# NiFi Node Server Wait

    module.exports = header: 'NiFi Node Server Wait', label_true: 'READY', timeout: -1, handler: ->
      {nifi} = @config.ryba
      @wait_connect
        servers: for ctx in @contexts 'ryba/nifi/node'
          host: ctx.config.host
          port: ctx.config.ryba.nifi.node.config.properties['nifi.cluster.node.protocol.port']
