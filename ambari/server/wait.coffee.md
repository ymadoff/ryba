
# Ambari Server Wait

    module.exports = header: 'Ambari Server Install', timeout: -1, handler: ->
      [ctx] = @contexts 'ryba/ambari/server'
      {ambari_server} = ctx.config.ryba
      clusters_url = url.format
        protocol: 'http'
        hostname: ctx.config.host
        port: ambari_server.config['client.api.port']
        pathname: '/api/v1/clusters'
      cred = "admin:#{ambari_server.admin_password}"
      @wait.execute
        cmd: """
        curl -u #{cred} #{clusters_url}
        """

## Dependencies

    url = require 'url'
