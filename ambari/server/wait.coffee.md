
# Ambari Server Wait

    module.exports = header: 'Ambari Server Wait', timeout: -1, handler: ->
      [ambari_ctx] = @contexts 'ryba/ambari/server'
      {ambari_server} = ambari_ctx.config.ryba
      
      clusters_url = url.format
        protocol: unless ambari_server.config['api.ssl'] is 'true'
        then 'http'
        else 'https'
        hostname: ambari_ctx.config.host
        port: unless ambari_server.config['api.ssl'] is 'true'
        then ambari_server.config['client.api.port']
        else ambari_server.config['client.api.ssl.port']
        pathname: '/api/v1/clusters'
      cred = "admin:#{ambari_server.admin_password}"
      @wait.execute
        cmd: """
        curl -k -u #{cred} #{clusters_url}
        """

## Dependencies

    url = require 'url'
