
# Atlas Metadata Server Wait

Wait for Atlas Metadata Server to start.

    module.exports = header: 'Atlas Wait', label_true: 'READY', handler: ->
      options = {}
      options.wait_http = for atlas_ctx in @contexts 'ryba/atlas'
        host: atlas_ctx.config.host
        port: if atlas_ctx.config.ryba.atlas.application.properties['atlas.enableTLS'] is 'true'
        then atlas_ctx.config.ryba.atlas.application.properties["atlas.server.https.port"]
        else atlas_ctx.config.ryba.atlas.application.properties["atlas.server.http.port"]

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.wait_http
