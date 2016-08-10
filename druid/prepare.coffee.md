
# Druid Prepare

Download the Druid package.

    module.exports = header: 'Druid Prepare', handler: ->
      {druid} = @config.ryba
      @cache
        ssh: null
        source: "#{druid.source}"
      
