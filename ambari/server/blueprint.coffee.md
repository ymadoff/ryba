
# Ambari Server start

Ambari server is started with the service's syntax command.

    module.exports = header: 'Ambari Server Export', handler: ->
      {ambari_server} = @config.ryba
      id = "#{Date.now()}"

## Blueprint

      clusters_url = url.format
        protocol: unless ambari_server.config['api.ssl'] is 'true'
        then 'http'
        else 'https'
        hostname: @config.host
        port: unless ambari_server.config['api.ssl'] is 'true'
        then ambari_server.config['client.api.port']
        else ambari_server.config['client.api.ssl.port']
        pathname: "/api/v1/clusters/#{ambari_server.cluster_name}"
        query: 'format': 'blueprint'
      cred = "admin:#{ambari_server.admin_password}"
      @system.execute
        header: "Blueprint"
        cmd: """
        curl -f -k -u #{cred} #{clusters_url}
        """
      , (err, status, stdout) -> @call (_, callback) ->
        throw err if err
        fs.writeFile "doc/blueprints/#{Date.now()}_blueprint.json", stdout, callback

## Hosts

      clusters_url = url.format
        protocol: unless ambari_server.config['api.ssl'] is 'true'
        then 'http'
        else 'https'
        hostname: @config.host
        port: unless ambari_server.config['api.ssl'] is 'true'
        then ambari_server.config['client.api.port']
        else ambari_server.config['client.api.ssl.port']
        pathname: "/api/v1/clusters/#{ambari_server.cluster_name}/hosts"
      cred = "admin:#{ambari_server.admin_password}"
      @system.execute
        header: "Hosts"
        cmd: """
        curl -f -k -u #{cred} #{clusters_url}
        """
      , (err, status, stdout) -> @call (_, callback) ->
        throw err if err
        fs.writeFile "doc/blueprints/#{Date.now()}_hosts.json", stdout, callback

## Dependencies

    url = require 'url'
    fs = require 'fs'
