
# Restart HBase

    module.exports = (options) ->
      @service
        header: 'HBase Master: Phoenix: Restart Master'
        srv_name: "hbase-master"
        action: 'restart'
        if: [
          @has_module 'ryba/hbase/master'
          -> @status()
        ]
      @service
        header: 'HBase Master: Phoenix: Restart RegionServer'
        srv_name: "hbase-regionserver"
        action: 'restart'
        if: [
          @has_module 'ryba/hbase/regionserver'
          -> @status()
        ]
