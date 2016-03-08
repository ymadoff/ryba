
    module.exports = 
      header: 'Solr Download'
      timeout: -1
      if: -> @contexts('ryba/solr')[0]?.config.host is @config.host
      handler: ->
        @cache
          ssh: null
          source: @config.ryba.solr.source
          location: true
