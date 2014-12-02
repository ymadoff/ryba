
# HDFS NameNode Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs').configure

    module.exports.push name: 'Hadoop HDFS NN # Wait', timeout: -1, callback: (ctx, next) ->
      nn_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      servers = for nn_host in nn_hosts
        nn_ctx = ctx.hosts[nn_host]
        require('./hdfs_nn').configure nn_ctx
        protocol = if nn_ctx.config.ryba.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        if nn_host.length # HA
          {nameservice, shortname} = nn_ctx.config.ryba
          port = nn_ctx.config.ryba.ha_client_config["dfs.namenode.#{protocol}-address.#{nameservice}.#{shortname}"].split(':')[1]
        else
          port = nn_ctx.config.ryba.hdfs_site["dfs.namenode.#{protocol}-address"].split(':')[1]
        host: nn_host, port: port
      ctx.waitIsOpen servers, next

    module.exports.push name: 'Hadoop HDFS NN # Wait Safemode', timeout: -1, callback: (ctx, next) ->
      ctx.waitForExecution
        cmd: mkcmd.hdfs ctx, """
          hdfs dfsadmin -safemode get | grep OFF
          """
        interval: 3000
      , (err) -> next err

## Module Dependencies

    mkcmd = require '../lib/mkcmd'
