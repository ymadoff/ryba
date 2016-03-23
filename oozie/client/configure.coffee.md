
# Oozie Client Configuration

    module.exports = handler: ->
      {ryba} = @config
      # Configuration
      ryba.oozie ?= {}
      # Layout
      ryba.oozie.conf_dir ?= '/etc/oozie/conf'
      # Configuration
      ryba.oozie.site ?= {}
      [o_ctx] = @contexts 'ryba/oozie/server', [require('../../hadoop/core/configure').handler , require('../server/configure').handler]
      ryba.oozie.site['oozie.base.url'] = o_ctx.config.ryba.oozie.site['oozie.base.url']
      ryba.oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] = o_ctx.config.ryba.oozie.site['oozie.service.HadoopAccessorService.kerberos.principal']
      # Remove password
      unless @has_module 'ryba/oozie/server'
        ryba.oozie.site['oozie.service.JPAService.jdbc.username'] = null
        ryba.oozie.site['oozie.service.JPAService.jdbc.password'] = null
