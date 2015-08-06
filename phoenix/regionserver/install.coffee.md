
# Phoenix on RegionServer

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../lib/enrich_hbase'
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require('./index').configure

## Packages

    module.exports.push name: 'Phoenix # Install', handler: (ctx, next) ->
      ctx
      .service name: 'phoenix'
      .hdp_select name: 'phoenix-client'
      .then next

## Env

    module.exports.push name: 'Phoenix RegionServer # Enrich HBase', handler: (ctx, next) ->
      ctx
      .phoenix_enrich_hbase {}
      .then next
