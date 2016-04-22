
# NiFi Manager Check

    module.exports = header: 'NiFI Manager Check', label_true: 'CHECKED', handler: ->
      {nifi} = @config.ryba
      protocol = if nifi.manager.config.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'
      webui = nifi.manager.config.properties["nifi.web.#{protocol}.port"]

## Wait
      
      @call once: true, 'ryba/nifi/manager/wait'

## Check TCP

Check if all Manager's port are opened
- Webui port
- broadcast port (port used to communicate with nodes)
- admin port (port used by node to authenticate)

      @execute
        header: 'Check Webui port'
        label_true: 'CHECKED'
        cmd: "echo > /dev/tcp/#{@config.host}/#{webui}"
      @execute
        header: 'Check Broadcast port'
        label_true: 'CHECKED'
        cmd: "echo > /dev/tcp/#{@config.host}/#{nifi.manager.config.properties['nifi.cluster.manager.protocol.port']}"
      @execute
        header: 'Check admin port'
        label_true: 'CHECKED'
        cmd: "echo > /dev/tcp/#{@config.host}/#{nifi.manager.config.authority_providers.ncm_port}"
      
## Check Rest Api
Executes a series of job to test NiFi functionning
curl -H "Content-Type: application/json" --negotiate -k  -X POST -d '[#{JSON.stringify pic}]' -u: https://
      #
