
# Ambari Server start

Ambari server is started with the service's syntax command.

    module.exports = header: 'Ambari Server Check', label_true: 'STARTED', handler: ->
      {ambari_server} = @config.ryba

## Check HTTP Server

      clusters_url = url.format
        protocol: 'http'
        hostname: @config.host
        port: ambari_server.config['client.api.port']
        pathname: '/api/v1/clusters'
      cred = "admin:#{ambari_server.admin_password}"
      @system.execute
        header: "Web"
        cmd: """
        curl -u #{cred} #{clusters_url}
        """

## Check Internal Port

      @connection.assert
        header: "Internal"
        host: @config.host
        port: ambari_server.config['server.url_port'] # TODO: detect SSL
        
## Dependencies

    url = require 'url'
