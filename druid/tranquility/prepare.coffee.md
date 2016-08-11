
# Druid Tranquility Prepare

Download the Tranquility package.

    module.exports = header: 'Druid Tranquility Prepare', handler: ->
      {druid} = @config.ryba
      @cache
        ssh: null
        source: "#{druid.tranquility.source}"
      
