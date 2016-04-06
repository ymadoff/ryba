# NiFi Manager Check

    module.exports = header: 'NiFI Node Check', label_true: 'CHECKED', handler: ->
      {nifi} = @config.ryba
      
## Check TCP

      @execute
        header: 'Check TCP port'
        label_true: 'CHECKED'
        cmd: "echo > /dev/tcp/#{@config.host}/#{nifi.node.config.properties['nifi.cluster.node.protocol.port']}"
