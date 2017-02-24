
# Druid Prepare

Download the Druid package.

    module.exports = header: 'Druid Prepare', handler: ->
      {druid} = @config.ryba
      @file.cache
        ssh: null
        source: "#{druid.source}"
