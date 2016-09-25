
# Shinken Arbiter Wait

    module.exports = header: 'Solr Cloud Wait', label_true: 'READY', handler: ->
      @connection.wait
        servers: for ctx in @contexts 'ryba/solr/cloud'
          host: ctx.config.host
          port: ctx.config.ryba.solr.cloud.port
