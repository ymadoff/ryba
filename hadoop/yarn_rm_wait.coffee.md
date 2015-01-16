
# Hadoop Yarn ResourceManager Wait

Wait for the ResourceManager RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Yarn RM # Wait RM', timeout: -1, label_true: 'READY', handler: (ctx, next) ->
      rm_ctxs = ctx.contexts modules: 'ryba/hadoop/yarn_rm', require('./yarn').configure
      servers = for rm_ctx in rm_ctxs
        {yarn} = rm_ctx.config.ryba
        protocol = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then '' else '.https'
        shortname = if rm_ctxs.length is 1 then '' else ".#{rm_ctx.config.shortname}"
        ports = []
        if rm_ctx.active_rm_host is rm_ctx.config.host # Only active is listening
          ports.push yarn.site["yarn.resourcemanager.address#{shortname}"].split(':')[1]
        ports.push yarn.site["yarn.resourcemanager.webapp#{protocol}.address#{shortname}"].split(':')[1]
        host: rm_ctx.config.host, port: ports
      ctx.waitIsOpen servers, next