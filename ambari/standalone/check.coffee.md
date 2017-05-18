
# Ambari Standalone start

Ambari Standalone is started with the service's syntax command.

    module.exports = header: 'Ambari Standalone Check', label_true: 'STARTED', handler: ->
      {ambari_standalone} = @config.ryba

Wait for the Ambari Server to be ready.

      @call once: true, 'ryba/ambari/standalone/wait'

## Check HTTP Server

      clusters_url = url.format
        protocol: unless ambari_standalone.config['api.ssl'] is 'true'
        then 'http'
        else 'https'
        hostname: @config.host
        port: unless ambari_standalone.config['api.ssl'] is 'true'
        then ambari_standalone.config['client.api.port']
        else ambari_standalone.config['client.api.ssl.port']
        pathname: '/api/v1/clusters'
      cred = "admin:#{ambari_standalone.admin_password}"
      @system.execute
        header: "Web"
        cmd: """
        curl -k -u #{cred} #{clusters_url}
        """

## Check Internal Port

      @connection.assert
        header: "Internal"
        host: @config.host
        port: ambari_standalone.config['server.url_port'] # TODO: detect SSL
        
## Dependencies

    url = require 'url'
