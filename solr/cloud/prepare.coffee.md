  
    module.exports = 
      header: 'Solr Cloud Download'
      timeout: -1
      if: -> @contexts('ryba/solr/cloud')[0]?.config.host is @config.host
      handler: ->
        @cache
          ssh: null
          source: @config.ryba.solr.cloud.source
          location: true
