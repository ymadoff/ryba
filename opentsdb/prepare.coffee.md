
# OpenTSDB Prepare

Download the rpm package.

    module.exports =
      header: 'OpenTSDB Prepare'
      timeout: -1
      if: -> @contexts('masson/commons/java')[0]?.config.host is @config.host
      handler: ->
        @cache
          ssh: null
          source: "#{@config.ryba.opentsdb.source}"
