
# Hadoop Yarn ResourceManager Wait

Wait for the ResourceManagers RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'Yarn RM # Wait RM', timeout: -1, label_true: 'READY', handler: ->
      rm_ctxs = @contexts modules: 'ryba/hadoop/yarn_rm' #, require('./index').configure
      @wait_connect
        servers: for rm_ctx in rm_ctxs
          {yarn} = rm_ctx.config.ryba
          protocol = if yarn.rm.site['yarn.http.policy'] is 'HTTP_ONLY' then '' else '.https'
          id = if yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
          host: rm_ctx.config.host, port: yarn.rm.site["yarn.resourcemanager.webapp#{protocol}.address#{id}"].split(':')[1]
