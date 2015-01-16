
# HBase Client Install

Install the HBase client package and configure it with secured access.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hbase/_'
    module.exports.push require('./client').configure

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master, 
RegionServer, and HBase client host machines.

    module.exports.push name: 'HBase Client # Zookeeper JAAS', timeout: -1, handler: (ctx, next) ->
      {jaas_client, hbase} = ctx.config.ryba
      ctx.write
        destination: "#{hbase.conf_dir}/hbase-client.jaas"
        content: jaas_client
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o700
      , next

## Check

Require the "ryba/hbase/client_check" module.

    module.exports.push 'ryba/hbase/client_check'



