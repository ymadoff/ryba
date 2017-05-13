
# Hadoop Yarn ResourceManager Wait

Wait for the ResourceManagers RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = header: 'YARN RM Wait', timeout: -1, label_true: 'READY', handler: ->
      options = {}
      options.wait_tcp = for rm_ctx in @contexts 'ryba/hadoop/yarn_rm'
        {yarn} = rm_ctx.config.ryba
        id = if yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
        [fqdn, port] = yarn.rm.site["yarn.resourcemanager.address#{id}"].split(':')
        host: fqdn, port: port
      options.wait_admin = for rm_ctx in @contexts 'ryba/hadoop/yarn_rm'
        {yarn} = rm_ctx.config.ryba
        id = if yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
        [fqdn, port] = yarn.rm.site["yarn.resourcemanager.admin.address#{id}"].split(':')
        host: fqdn, port: port
      options.wait_webapp = for rm_ctx in @contexts 'ryba/hadoop/yarn_rm'
        {yarn} = rm_ctx.config.ryba
        protocol = if yarn.rm.site['yarn.http.policy'] is 'HTTP_ONLY' then '' else '.https'
        id = if yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
        host: rm_ctx.config.host, port: yarn.rm.site["yarn.resourcemanager.webapp#{protocol}.address#{id}"].split(':')[1]

## TCP

The RM address isnt listening on port 8050 unless the node is active. This is
the reason why quorum is set to "1".

      @connection.wait
        header: 'TCP'
        quorum: 1
        servers: options.wait_tcp

## Admin

      @connection.wait
        header: 'Admin'
        servers: options.wait_admin

## Webapp Address

      @connection.wait
        header: 'Webapp'
        servers: options.wait_webapp
