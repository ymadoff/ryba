
# NiFi Prepare

Download the additional jars

    module.exports =
      header: 'NiFi Prepare'
      timeout: -1
      if: -> @contexts('ryba/nifi')[0]?.config.host is @config.host
      handler: ->
        @file.cache
          ssh: null
          source: "#{@config.ryba.nifi.logback.core.source}"
          location: true
        @file.cache
          ssh: null
          source: "#{@config.ryba.nifi.logback.classic.source}"
          location: true
        @file.cache
          ssh: null
          source: "#{@config.ryba.nifi.logback.access.source}"
          location: true
        @file.cache
          ssh: null
          source: "#{@config.ryba.nifi.logback.socketappender.source}"
          location: true
