
# Oozie Client

Oozie is a server based Workflow Engine specialized in running workflow jobs
with actions that run Hadoop Map/Reduce and Pig jobs.

The Oozie server installation includes the Oozie client. The Oozie client should
be installed in remote machines only.

    module.exports = []

    module.exports.configure = (ctx) ->
      require('../../hadoop/core').configure ctx
      {ryba} = ctx.config
      # Configuration
      ryba.oozie ?= {}
      # Layout
      ryba.oozie.conf_dir ?= '/etc/oozie/conf'
      # Configuration
      ryba.oozie.site ?= {}
      [o_ctx] = ctx.contexts modules: 'ryba/oozie/server', require('../server').configure
      ryba.oozie.site['oozie.base.url'] = o_ctx.config.ryba.oozie.site['oozie.base.url']
      ryba.oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] = o_ctx.config.ryba.oozie.site['oozie.service.HadoopAccessorService.kerberos.principal']
      # Remove password
      unless ctx.has_module 'ryba/oozie/server'
        ryba.oozie.site['oozie.service.JPAService.jdbc.username'] = null
        ryba.oozie.site['oozie.service.JPAService.jdbc.password'] = null

## Commands

    module.exports.push commands: 'install', modules: [
      'ryba/oozie/client/install'
      'ryba/oozie/client/check'
    ]

    module.exports.push commands: 'check', modules: 'ryba/oozie/client/check'
