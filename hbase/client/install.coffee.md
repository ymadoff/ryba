
# HBase Client Install

Install the HBase client package and configure it with secured access.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/mapred_client' # Required for using/checking mapreduce
    module.exports.push 'ryba/hbase'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/write_jaas'

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

    module.exports.push name: 'HBase Client # Zookeeper JAAS', timeout: -1, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.write_jaas
        destination: "#{hbase.conf_dir}/hbase-client.jaas"
        content: Client:
          useTicketCache: 'true'
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o644
      , next

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the client.

    module.exports.push name: 'HBase Client # Configure', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../../resources/hbase/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true
      .then next

## Check

Require the "ryba/hbase/client/check" module.

    module.exports.push 'ryba/hbase/client/check'
