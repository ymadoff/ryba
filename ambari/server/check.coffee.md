
# Ambari Server start

Ambari server is started with the service's syntax command.

    module.exports = header: 'Ambari Server Check', label_true: 'STARTED', handler: (options) ->

Wait for the Ambari Server to be ready.

      @call once: true, 'ryba/ambari/server/wait',
        fqdn: options.fqdn
        current_admin_password: options.current_admin_password
        admin_password: options.admin_password
        config: options.config

## Check HTTP Server

      clusters_url = url.format
        protocol: unless options.config['api.ssl'] is 'true'
        then 'http'
        else 'https'
        hostname: @config.host
        port: unless options.config['api.ssl'] is 'true'
        then options.config['client.api.port']
        else options.config['client.api.ssl.port']
        pathname: '/api/v1/clusters'
      cred = "admin:#{options.admin_password}"
      @system.execute
        header: "Web"
        cmd: """
        curl -f -k -u #{cred} #{clusters_url}
        """

## Check Internal Port

      @connection.assert
        header: "Internal"
        host: @config.host
        port: options.config['server.url_port'] # TODO: detect SSL
        
## Dependencies

    url = require 'url'
