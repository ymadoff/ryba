
# Cloudera Manager Parcels

Syncronize Cloudera parcels locally and setup an HTTP server.


    module.exports =
      commands:
        'prepare': ->
          @call
            if: -> @contexts('ryba/cloudera_manager/server')[0]?.config.host is @config.host
            ssh: null
            distrib: @config.cloudera_manager.distrib
            services: @config.cloudera_manager.distrib
            handler: 'ryba/cloudera-manager/server/prepare'
