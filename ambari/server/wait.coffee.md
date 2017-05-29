
# Ambari Server Wait

    module.exports = header: 'Ambari Server Wait', handler: (options) ->

## REST Access

      clusters_url = url.format
        protocol: unless options.config['api.ssl'] is 'true'
        then 'http'
        else 'https'
        hostname: options.fqdn
        port: unless options.config['api.ssl'] is 'true'
        then options.config['client.api.port']
        else options.config['client.api.ssl.port']
        pathname: '/api/v1/clusters'
      oldcred = "admin:#{options.current_admin_password}"
      newcred = "admin:#{options.admin_password}"
      @wait.execute
        header: 'REST'
        cmd: """
        curl -f -k -u #{newcred} #{clusters_url} || curl -f -k -u #{oldcred} #{clusters_url}
        """
        code_skipped: 7

## Dependencies

    url = require 'url'
