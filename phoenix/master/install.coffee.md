
# Phoenix on Master

    module.exports = ->
      @service name: 'phoenix'
      @hdp_select name: 'phoenix-client'
      @call require '../lib/hbase_enrich'
