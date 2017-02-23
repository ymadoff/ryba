
    module.exports = 
      header: 'Solr Download'
      timeout: -1
      if: -> @contexts('ryba/solr/standalone')[0]?.config.host is @config.host
      handler: ->
        @file.cache
          ssh: null
          source: @config.ryba.solr.single.source
          location: true
