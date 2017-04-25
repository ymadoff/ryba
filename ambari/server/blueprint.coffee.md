
# Ambari Server start

Ambari server is started with the service's syntax command.

    module.exports = header: 'Ambari Server Export', handler: ->
      {ambari_server} = @config.ryba
      id = "#{Date.now()}"

## Blueprint

http://s07903v0.snm.snecma:8080/api/v1/blueprints

      clusters_url = url.format
        protocol: 'http'
        hostname: @config.host
        port: ambari_server.config['client.api.port']
        pathname: '/api/v1/clusters/dev_01'
        query: 'format': 'blueprint'
      cred = "admin:#{ambari_server.admin_password}"
      @system.execute
        header: "Blueprint"
        cmd: """
        curl -u #{cred} #{clusters_url}
        """
      , (err, status, stdout) -> @call (_, callback) ->
        throw err if err
        fs.writeFile "doc/blueprints/#{Date.now()}_blueprint.json", stdout, callback

## Hosts

      clusters_url = url.format
        protocol: 'http'
        hostname: @config.host
        port: ambari_server.config['client.api.port']
        pathname: '/api/v1/clusters/dev_01/hosts'
      cred = "admin:#{ambari_server.admin_password}"
      @system.execute
        header: "Hosts"
        cmd: """
        curl -u #{cred} #{clusters_url}
        """
      , (err, status, stdout) -> @call (_, callback) ->
        throw err if err
        fs.writeFile "doc/blueprints/#{Date.now()}_hosts.json", stdout, callback

## Dependencies

    url = require 'url'
    fs = require 'fs'
