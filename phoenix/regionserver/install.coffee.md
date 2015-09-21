
# Phoenix on RegionServer

    module.exports = ->
      @service name: 'phoenix'
      @hdp_select name: 'phoenix-client'
      @call require '../lib/hbase_enrich'
