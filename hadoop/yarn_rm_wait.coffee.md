
# Yarn ResourceManager Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Hadoop NodeManager # Wait RM', timeout: -1, callback: (ctx, next) ->
      rm_hosts = ctx.hosts_with_module 'ryba/hadoop/yarn_rm'
      servers = []
      for rm_host in rm_hosts
        rm_ctx = ctx.hosts[rm_host]
        require('./yarn_rm').configure(rm_ctx)
        {yarn_site} = rm_ctx.config.ryba
        rpc_port = yarn_site['yarn.resourcemanager.address'].split(':')[1]
        http_port = if yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
        then yarn_site['yarn.resourcemanager.webapp.address'].split(':')[1]
        else yarn_site['yarn.resourcemanager.webapp.https.address'].split(':')[1]
        servers.push host: rm_host, port: rpc_port
        servers.push host: rm_host, port: http_port
      ctx.waitIsOpen servers, next