
# Atlas Metadata Server Wait

Wait for Atlas Metadata Server to start.

    module.exports = header: 'Atlas Wait', label_true: 'READY', handler: ->
      atlas_servers = @contexts 'ryba/atlas'
      @connection.wait
        servers: for atlas_ in atlas_servers
          host: atlas_.config.host
          port: if atlas_.config.ryba.atlas.application.properties['atlas.enableTLS'] is 'true'
          then atlas_.config.ryba.atlas.application.properties["atlas.server.https.port"]
          else atlas_.config.ryba.atlas.application.properties["atlas.server.http.port"]
