
# Hive & HCat Server Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Hive & HCat Server # Wait metastore', timeout: -1, callback: (ctx, next) ->
      hosts = ctx.hosts_with_module 'ryba/hive/server'
      servers = []
      for host in hosts
        lctx = ctx.hosts[host]
        require('./server').configure(lctx)
        server2_port = lctx.config.ryba.hive_site['hive.server2.thrift.port']
        metastore_port = lctx.config.ryba.hive_site['hive.metastore.uris'].split(':')[2]
        servers.push host: host, port: server2_port
        servers.push host: host, port: metastore_port
      ctx.waitIsOpen servers, next