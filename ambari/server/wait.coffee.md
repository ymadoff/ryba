
# Ambari Server Wait

    module.exports = header: 'Ambari Server Install', timeout: -1, handler: ->
      [ctx] = @contexts 'ryba/ambari/server'
      server_url = url.parse
        protocol: 'http'
        host: ctx.config.host
        port: ambari_server.config['client.api.port']
        auth: 
      @wait.execute
        cmd: """
        
        curl --user name:password http://#{ctx.config.host}:#{ctx.config.ambari_server.config['client.api.port']}/api/v1/clusters
        """
