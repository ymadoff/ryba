

    module.exports = 
      header: 'Nifi Download'
      timeout: -1
      if: -> @contexts('ryba/nifi/manager')[0]?.config.host is @config.host
      handler: ->
        @cache
          ssh: null
          source: @config.ryba.nifi.source
          location: true
