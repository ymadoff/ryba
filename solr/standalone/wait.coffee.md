
# Shinken Arbiter Wait

    module.exports = header: 'Solr Standalone Wait', label_true: 'READY', handler: ->
      @connection.wait
        servers: for ctx in @contexts 'ryba/solr/standalone'
          host: ctx.config.host
          port: ctx.config.ryba.solr.single.port
