
# Titan Prepare

Download the rpm package.

    module.exports =
      header: 'Titan Prepare'
      timeout: -1
      if: -> @contexts('ryba/titan')[0]?.config.host is @config.host
      handler: ->
        @cache
          ssh: null
          source: "#{@config.ryba.titan.source}"
